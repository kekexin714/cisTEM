#include "gpu_core_headers.h"



TemplateMatchingCore::TemplateMatchingCore() 
{

};

TemplateMatchingCore::TemplateMatchingCore(int number_of_jobs) 
{

  Init(number_of_jobs);


};



TemplateMatchingCore::~TemplateMatchingCore() 
{

 // THis


};

void TemplateMatchingCore::Init(int number_of_jobs)
{
  this->nThreads = 1;
	this->number_of_jobs_per_image_in_gui = 1;
  this->nGPUs = 1;


};

void TemplateMatchingCore::Init(Image &template_reconstruction,
                                Image &input_image,
                                Image &projection_filter,
                                Image &current_projection,
                                float pixel_size_search_range,
                                float pixel_size_step,
                                float pixel_size,
                                float defocus_search_range,
                                float defocus_step,
                                float defocus1,
                                float defocus2,
                                float psi_max,
                                float psi_start,
                                float psi_step,
                                AnglesAndShifts angles,
                                EulerSearch global_euler_search,
                                int first_search_position,
                                int last_search_position)
                                
{



  this->first_search_position = first_search_position;
  this->last_search_position  = last_search_position;
  this->angles = angles;
  this->global_euler_search = global_euler_search;

  this->psi_start = psi_start;
  this->psi_step  = psi_step;
  this->psi_max   = psi_max;

//	this->gpuDev.Init(this->nGPUs);


  
//    this->gpuDev.SetGpu(omp_get_thread_num());
  
    // It seems that I need a copy for these - 1) confirm, 2) if already copying, maybe put straight into pinned mem with cudaHostMalloc
    this->template_reconstruction.CopyFrom(&template_reconstruction);
    this->input_image.CopyFrom(&input_image);
    this->current_projection.CopyFrom(&current_projection);

    d_input_image.Init(this->input_image);
    d_input_image.CopyHostToDevice();

    d_current_projection.Init(this->current_projection);
    d_projection_filter.Init(projection_filter);

    d_padded_reference.Allocate(d_input_image.dims.x, d_input_image.dims.y, d_input_image.dims.z, true);
    d_max_intensity_projection.Allocate(d_input_image.dims.x, d_input_image.dims.y, d_input_image.dims.z, true);
    d_best_psi.Allocate(d_input_image.dims.x, d_input_image.dims.y, d_input_image.dims.z, true);
    d_best_theta.Allocate(d_input_image.dims.x, d_input_image.dims.y, d_input_image.dims.z, true);
    d_best_psi.Allocate(d_input_image.dims.x, d_input_image.dims.y, d_input_image.dims.z, true);

    d_sum1.Allocate(d_input_image.dims.x, d_input_image.dims.y, d_input_image.dims.z, true);
    d_sum2.Allocate(d_input_image.dims.x, d_input_image.dims.y, d_input_image.dims.z, true);
    d_sum3.Allocate(d_input_image.dims.x, d_input_image.dims.y, d_input_image.dims.z, true);
    d_sum4.Allocate(d_input_image.dims.x, d_input_image.dims.y, d_input_image.dims.z, true);
    d_sum5.Allocate(d_input_image.dims.x, d_input_image.dims.y, d_input_image.dims.z, true);

    d_sumSq1.Allocate(d_input_image.dims.x, d_input_image.dims.y, d_input_image.dims.z, true);
    d_sumSq2.Allocate(d_input_image.dims.x, d_input_image.dims.y, d_input_image.dims.z, true);
    d_sumSq3.Allocate(d_input_image.dims.x, d_input_image.dims.y, d_input_image.dims.z, true);
    d_sumSq4.Allocate(d_input_image.dims.x, d_input_image.dims.y, d_input_image.dims.z, true);
    d_sumSq5.Allocate(d_input_image.dims.x, d_input_image.dims.y, d_input_image.dims.z, true);
    
    // For now we are only working on the inner loop, so no need to track best_defocus and best_pixel_size

    // At the outset these are all empty cpu images, so don't xfer, just allocate on gpuDev



    // Transfer the input image_memory_should_not_be_deallocated  

    cudaStreamSynchronize(cudaStreamPerThread);

};

void TemplateMatchingCore::RunInnerLoop(float c_pixel, float c_defocus, int threadIDX)
{


  
//  // TODO should this be swapped? Can it just be passed as FFT?
//  d_input_image.ForwardFFT(); // This is for the standalone test
//  template_reconstruction.ForwardFFT(); // This is for the standalone test
//  template_reconstruction.SwapRealSpaceQuadrants(); // This is for the standalone test

  // Make sure we are starting with zeros
  d_max_intensity_projection.Zeros();
  d_best_psi.Zeros();
  d_best_phi.Zeros();
  d_best_theta.Zeros();
  d_padded_reference.Zeros();
  d_current_projection.Zeros();


  d_sum1.Zeros();
  d_sum2.Zeros();
  d_sum3.Zeros();
  d_sum4.Zeros();
  d_sum5.Zeros();

  d_sumSq1.Zeros();
  d_sumSq2.Zeros();
  d_sumSq3.Zeros();
  d_sumSq4.Zeros();
  d_sumSq5.Zeros();
    

  this->c_defocus = c_defocus;
  this->c_pixel = c_pixel;
  total_number_of_cccs_calculated = 0;




//  this->gpuDev.ReSetGpu();

  cudaEvent_t projection_is_free_Event, gpu_work_is_done_Event;
  checkCudaErrors(cudaEventCreateWithFlags(&projection_is_free_Event, cudaEventDisableTiming));
  checkCudaErrors(cudaEventCreateWithFlags(&gpu_work_is_done_Event, cudaEventDisableTiming));

  // Need to copy in the projection filter for this loop.
  d_projection_filter.CopyHostToDevice();
//  d_projection_filter.ForwardFFT(true); // This is for the standalone test
  d_projection_filter.Wait();
  d_projection_filter.QuickAndDirtyWriteSlices("/tmp/small_Prj_filter.mrc",1,1);




  long ccc_counter = 0;
  int current_search_position;
  float average_on_edge; 

	for (current_search_position = first_search_position; current_search_position <= last_search_position; current_search_position++)
	{

    wxPrintf("Starting position %d/ %d\n", current_search_position, last_search_position);
		for (float current_psi = psi_start; current_psi <= psi_max; current_psi += psi_step)
		{

		  angles.Init(global_euler_search.list_of_search_parameters[current_search_position][0], global_euler_search.list_of_search_parameters[current_search_position][1], current_psi, 0.0, 0.0);

//      wxPrintf("Pos %d working on phi, theta, psi, %3.3f %3.3f %3.3f \n", current_search_position, (float)global_euler_search.list_of_search_parameters[current_search_position][0], (float)global_euler_search.list_of_search_parameters[current_search_position][1], (float)current_psi);
      // FIXME not padding enabled
      // HOST project. Note that the projection has mean set to zero but it is probably better to ensure this here as it is cheap.

      template_reconstruction.ExtractSlice(current_projection, angles, 1.0f, false);
      current_projection.complex_values[0] = 0.0f + I * 0.0f;


      current_projection.SwapRealSpaceQuadrants();


////      current_projection.MultiplyPixelWise(*d_projection_filter.hostImage);
//      current_projection.BackwardFFT();
//      average_on_edge = current_projection.ReturnAverageOfRealValuesOnEdges();
//      current_projection.AddConstant(-average_on_edge);
////      current_projection.MultiplyByConstant( 1.0f / sqrtf( current_projection.ReturnSumOfSquares() * current_projection.number_of_real_space_pixels /
////                                                           d_padded_reference.number_of_real_space_pixels - (average_on_edge*average_on_edge) ));
//      // TODO add more?

      // Make sure the device has moved on to the padded projection
      cudaStreamWaitEvent(cudaStreamPerThread,projection_is_free_Event, 0);

    
      d_current_projection.CopyHostToDevice();

      d_current_projection.MultiplyPixelWise(d_projection_filter);
      d_current_projection.BackwardFFT();
      average_on_edge = d_current_projection.ReturnAverageOfRealValuesOnEdges();


//      // To check
//      average_on_edge = d_current_projection.ReturnAverageOfRealValuesOnEdges();
//       

      d_current_projection.MultiplyByConstant(1.0f / (sqrtf(  d_current_projection.ReturnSumOfSquares() / (float)d_padded_reference.number_of_real_space_pixels) - 
                                                            (average_on_edge * average_on_edge)));


//      d_padded_reference.Zeros(); // TODO this should not be needed.

      d_current_projection.ClipInto(&d_padded_reference, 0, false, 0, 0, 0, 0);
      cudaEventRecord(projection_is_free_Event, cudaStreamPerThread);

//      cudaStreamSynchronize(cudaStreamPerThread);
//      std::string fileNameOUT4 = "/tmp/checkPaddedRef" + std::to_string(threadIDX) + ".mrc";
//      d_padded_reference.QuickAndDirtyWriteSlices(fileNameOUT4, 1, 1); 

      d_padded_reference.ForwardFFT();
      // The input image should have zero mean, so multipling also zeros the mean of the ref.
      d_padded_reference.MultiplyPixelWiseComplexConjugate(d_input_image);
      d_padded_reference.BackwardFFT();




      d_max_intensity_projection.MipPixelWise(d_padded_reference, d_best_psi, d_best_psi, d_best_theta, 
                                              current_psi,
                                              global_euler_search.list_of_search_parameters[current_search_position][0],
                                              global_euler_search.list_of_search_parameters[current_search_position][1]);


      // TODO these ops have no interdependency so could go into two accumulator strings with an event wait prior to the next use of padded reference.
      d_max_intensity_projection.Wait();
      d_sum1.AddImage(d_padded_reference);
      d_sumSq1.AddSquaredImage(d_padded_reference);

      int maxAccumulator = 0;

      if ( ccc_counter % 10 == 0 )
      {
          d_sum2.AddImage(d_sum1); d_sum1.Zeros();
          d_sumSq2.AddImage(d_sumSq1); d_sumSq1.Zeros();

      }
      if ( ccc_counter % 100 == 0 )
      {
          d_sum3.AddImage(d_sum2); d_sum2.Zeros();
          d_sumSq3.AddImage(d_sumSq2); d_sumSq2.Zeros();

      }
      if ( ccc_counter % 10000 == 0 )
      {
          d_sum4.AddImage(d_sum3); d_sum3.Zeros();
          d_sumSq4.AddImage(d_sumSq3); d_sumSq3.Zeros();

      }
      if ( ccc_counter % 100000000 == 0 ) 
      {
          d_sum5.AddImage(d_sum4); d_sum4.Zeros();
          d_sumSq5.AddImage(d_sumSq4); d_sumSq4.Zeros();

      }


      current_projection.is_in_real_space = false;
      d_padded_reference.is_in_real_space = true;
      cudaEventRecord(gpu_work_is_done_Event, cudaStreamPerThread);

      
      ccc_counter++;
      total_number_of_cccs_calculated++;


		} // loop over psi angles


//      if (current_search_position % 10 == 0)
//      {
//        std::string fileNameOUT4 = "/tmp/tmpMip" + std::to_string(current_search_position) + ".mrc";
////      d_padded_reference.QuickAndDirtyWriteSlices(fileNameOUT3, 1, 1);
//        d_max_intensity_projection.SwapRealSpaceQuadrants();
//        d_max_intensity_projection.QuickAndDirtyWriteSlices(fileNameOUT4,1,1);
//        d_max_intensity_projection.SwapRealSpaceQuadrants();
//      }
//      if (current_search_position > 20)
//      {
//        exit(-1);
//      }

      
 	} // end of outer loop euler sphere position


    checkCudaErrors(cudaStreamSynchronize(cudaStreamPerThread));

//        d_max_intensity_projection.SwapRealSpaceQuadrants();
//        d_max_intensity_projection.QuickAndDirtyWriteSlices("/tmp/mip.mrc",1,1);

//        exit(-1);
  


  // TODO return results to the host
  
}





