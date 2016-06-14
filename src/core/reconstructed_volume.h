/*  \brief  ReconstructedVolume class */

class Reconstruct3D;
class NumericTextFile;

class ReconstructedVolume {

public:

	float						pixel_size;
	float						mask_volume_in_voxels;
	float						molecular_mass_in_kDa;
	wxString 					symmetry_symbol;
	SymmetryMatrix				symmetry_matrices;
	Image						density_map;
	Image						current_projection;
	ResolutionStatistics		statistics;
	float						current_resolution_limit;
	float						current_ctf;
	float						current_phi;
	float						current_theta;
	float						current_psi;
	float						current_shift_x;
	float						current_shift_y;
	float						current_mask_radius;
	float						current_mask_falloff;
	bool						current_whitening;
	bool						current_swap_quadrants;

	bool						has_been_initialized;
	bool						has_masked_applied;
	bool						was_corrected;
	bool						has_statistics;
	bool						has_been_filtered;
	bool						whitened_projection;

	ReconstructedVolume();
	~ReconstructedVolume();

	ReconstructedVolume & operator = (const ReconstructedVolume &t);
	ReconstructedVolume & operator = (const ReconstructedVolume *t);

	void Deallocate();
	void InitWithReconstruct3D(Reconstruct3D &image_reconstruction, float wanted_pixel_size);
	void InitWithDimensions(int wanted_logical_x_dimension, int wanted_logical_y_dimension, int wanted_logical_z_dimension, float wanted_pixel_size, wxString = "C1");
	void PrepareForProjections(float resolution_limit, bool approximate_binning = false);
	void CalculateProjection(Image &projection, Image &CTF, AnglesAndShifts &angles_and_shifts_of_projection, float mask_radius = 0.0, float mask_falloff = 0.0, float resolution_limit = 1.0, bool swap_quadrants = true, bool whiten = false);
	void Calculate3DSimple(Reconstruct3D &reconstruction);
	void Calculate3DOptimal(Reconstruct3D &reconstruction, float pssnr_correction_factor = 1.0);
	float Correct3D(float mask_radius = 0.0);
	void CosineRingMask(float wanted_inner_mask_radius, float wanted_outer_mask_radius, float wanted_mask_edge);
	void CosineMask(float wanted_mask_radius, float wanted_mask_edge);
	void OptimalFilter();
	void PrintStatistics();
	void WriteStatisticsToFile(NumericTextFile &output_statistics_file);
	void ReadStatisticsFromFile(wxString input_file);
	void GenerateDefaultStatistics();
};
