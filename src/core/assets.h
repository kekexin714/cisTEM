#ifndef __ASSETS_H__
#define __ASSETS_H__

class Asset {

public :

	int asset_id;
	int parent_id;
	wxFileName filename;
	bool is_valid;

	Asset();
	~Asset();

	// pure virtual


	wxString ReturnFullPathString();
	wxString ReturnShortNameString();

};

class MovieAsset : public Asset {

  public:

	MovieAsset();
	MovieAsset(wxString wanted_filename);
	~MovieAsset();

	int position_in_stack;

	int x_size;
	int y_size;
	int number_of_frames;
	

	double pixel_size;
	double microscope_voltage;
	double spherical_aberration;
	double dose_per_frame;
	double total_dose;

	void Update(wxString wanted_filename);
	//void Recheck_if_valid();
	void CopyFrom(Asset *other_asset);
	//long FindMember(long member_to_find);

};

class ImageAsset : public Asset {

  public:

	ImageAsset();
	ImageAsset(wxString wanted_filename);
	~ImageAsset();

	int position_in_stack;
	int alignment_id;
	int ctf_estimation_id;

	int x_size;
	int y_size;

	double pixel_size;
	double microscope_voltage;
	double spherical_aberration;

	void Update(wxString wanted_filename);
	void CopyFrom(Asset *other_asset);
};

class ParticlePositionAsset : public Asset {

  public:

	ParticlePositionAsset();
	~ParticlePositionAsset();

	int pick_job_id;

	double x_position;
	double y_position;

	void CopyFrom(Asset *other_asset);
};


class AssetList {

protected :

	long number_allocated;

public :

	AssetList();
	~AssetList();

	long number_of_assets;

	Asset *assets;

	virtual void AddAsset(Asset *asset_to_add) = 0;
	virtual void RemoveAsset(long number_to_remove) = 0;
	virtual void RemoveAll() = 0;
//	virtual long FindFile(wxFileName file_to_find) = 0;
	virtual void CheckMemory() = 0;
	virtual Asset * ReturnAssetPointer(long wanted_asset) = 0;
	virtual MovieAsset * ReturnMovieAssetPointer(long wanted_asset);
	virtual ImageAsset * ReturnImageAssetPointer(long wanted_asset);
	virtual ParticlePositionAsset * ReturnParticlePositionAssetPointer(long wanted_asset);
	virtual int ReturnAssetID(long wanted_asset) = 0;
	virtual int ReturnArrayPositionFromID(int wanted_id) = 0;
	virtual int ReturnArrayPositionFromParentID(int wanted_id) = 0;

	long ReturnNumberOfAssets();
};


class MovieAssetList : public AssetList {

public:
	
	MovieAssetList();
	~MovieAssetList();
	

	Asset * ReturnAssetPointer(long wanted_asset);
	MovieAsset * ReturnMovieAssetPointer(long wanted_asset);

	int ReturnAssetID(long wanted_asset);
	int ReturnArrayPositionFromID(int wanted_id);
	int ReturnArrayPositionFromParentID(int wanted_id);

	void AddAsset(Asset *asset_to_add);
	void RemoveAsset(long number_to_remove);
	void RemoveAll();
	long FindFile(wxFileName file_to_find);
	void CheckMemory();

};

class ImageAssetList : public AssetList {

public:

	ImageAssetList();
	~ImageAssetList();


	Asset * ReturnAssetPointer(long wanted_asset);
	ImageAsset * ReturnImageAssetPointer(long wanted_asset);

	int ReturnAssetID(long wanted_asset);
	int ReturnArrayPositionFromID(int wanted_id);
	int ReturnArrayPositionFromParentID(int wanted_id);

	void AddAsset(Asset *asset_to_add);
	void RemoveAsset(long number_to_remove);
	void RemoveAll();
	long FindFile(wxFileName file_to_find);
	void CheckMemory();

};

class ParticlePositionAssetList : public AssetList {

public:

	ParticlePositionAssetList();
	~ParticlePositionAssetList();


	Asset * ReturnAssetPointer(long wanted_asset);
	ParticlePositionAsset * ReturnParticlePositionAssetPointer(long wanted_asset);

	int ReturnAssetID(long wanted_asset);
	int ReturnArrayPositionFromID(int wanted_id);
	int ReturnArrayPositionFromParentID(int wanted_id);

	void AddAsset(Asset *asset_to_add);
	void RemoveAsset(long number_to_remove);
	void RemoveAll();
	void CheckMemory();

};

#endif
