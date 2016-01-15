/*  \brief  RotationMatrix class */

class RotationMatrix {

public:

	float		m[3][3];                /* 3D rotation matrix*/

	RotationMatrix();
//	~RotationMatrix();

	RotationMatrix operator + (const RotationMatrix &other);
	RotationMatrix operator - (const RotationMatrix &other);
	RotationMatrix operator * (const RotationMatrix &other);
	RotationMatrix &operator = (const RotationMatrix &other);
	RotationMatrix &operator = (const RotationMatrix *other);
	RotationMatrix &operator += (const RotationMatrix &other);
	RotationMatrix &operator += (const RotationMatrix *other);
	RotationMatrix &operator -= (const RotationMatrix &other);
	RotationMatrix &operator -= (const RotationMatrix *other);
	RotationMatrix &operator *= (const RotationMatrix &other);
	RotationMatrix &operator *= (const RotationMatrix *other);
	RotationMatrix ReturnTransposed();
	void SetToIdentity();
	void SetToConstant(float constant);
	inline void RotateCoords(float &input_x_coord, float &input_y_coord, float &input_z_coord, float &output_x_coord, float &output_y_coord, float &output_z_coord)
	{
		output_x_coord = this->m[0][0] * input_x_coord + this->m[0][1] * input_y_coord + this->m[0][2] * input_z_coord;
		output_y_coord = this->m[1][0] * input_x_coord + this->m[1][1] * input_y_coord + this->m[1][2] * input_z_coord;
		output_z_coord = this->m[2][0] * input_x_coord + this->m[2][1] * input_y_coord + this->m[2][2] * input_z_coord;
	};
};
