module renderer.math;

import std.traits :
  isNumeric,
  isFloatingPoint;

struct Mesh(T)
{
  Triangle!(T)[] triangles;
  size_t length() const {
      return triangles.length;
  }
}

struct Triangle(T)
{
  import renderer.window;
  enum rows = 3;
  this(T[3][3] data)
  {
    for(int i = 0 ; i < 3; ++i){
        points[i][0] = data[i][0];
        points[i][1] = data[i][1];
        points[i][2] = data[i][2];
    }
  }
  Vector!(T, 3)[3] points;

  string toString() const {
      string returnVal;
      for(int i = 0; i < points.length; ++i){
          returnVal ~= points[i].toString();
      }
      return returnVal;
  }
  Colour colour;
}

struct Vector(T, size_t size)
{  
  static assert (isNumeric!T, "Error: struct Vector only accepts templates of type isNumeric");
  T[size] data;

  T length() const
  {
    return size;
  }
  Point toPoint() const {
    Point p = { cast(int)data[0], cast(int)data[1] };
    return p;
  }
  
  ref T opDispatch(string name)() {
    static if (name == "x" || name == "r") {
      return data[0];
    } else if (name == "y" || name == "g") {
      return data[1];
    } else if (name == "z" || name == "b") {
      return data[2];
    } else if (name == "w" || name == "a") {
      return data[3];
    }
    assert(0);
  }
  
  void opAssign(T[] arr)
  {
      assert(arr.length == size);
      data = arr;
  }
  
  ref T opIndex(size_t i) 
  {
    return data[i];
  }
  
  const string toString()
  {
    import std.format : format;
    return format("[%(%s %)]\n", data);
  }
  
  static float dot(V)(V vecA,V vecB)
  if (is (V == Vector!(T,size), T, size_t size) &&
      size >= 3)
  {
    float val = 0;
    for(int i = 0 ; i < 3; ++i) {
      val += vecA[i] * vecB[i];
    }
    return val;
  }
  
  static Vector!(float, 4) cross(V)(V a,V b)
     if (is (V == Vector!(T,size), T, size_t size))
  {
    Vector!(float, 4) c;
    c.x = a.y * b.z - a.z * b.y;
    c.y = a.z * b.x - a.x * b.z;
    c.z = a.x * b.y - a.y * b.x;
    return c;
  }
}

struct Mat(T, size_t rows, size_t cols)
{
  static assert (isNumeric!T, "Error: class Matrix only accepts templates of type isNumeric");
  T[rows * cols] data = 0;

  ref T opIndex(size_t r, size_t c) 
  {
    return data[c + r * cols];
  }

  T opIndex(size_t r, size_t c) const
  {
    return data[c + r * cols];
  }

  auto opBinary(string op : `*`, size_t k)(Vector!(T, k) vec) {
    Vector!(T, k) newVector = {0};
    newVector[0] = vec[0] * this[0,0] + vec[1] * this[1,0] + vec[2] * this[2,0] + this[3,0];
    newVector[1] = vec[0] * this[0,1] + vec[1] * this[1,1] + vec[2] * this[2,1] + this[3,1];
    newVector[2] = vec[0] * this[0,2] + vec[1] * this[1,2] + vec[2] * this[2,2] + this[3,2];
    float w =      vec[0] * this[0,3] + vec[1] * this[1,3] + vec[2] * this[2,3] + this[3,3];

    if (w != 0.0f) {
      newVector[0] /= w;
      newVector[1] /= w;
      newVector[2] /= w;
    }

    return newVector;
  }

  auto opBinary(string op : `*`, size_t k)(Mat!(T,cols,k) rhs)
  {
    Mat!(float,rows,k) newMatrix = {0};
    for(size_t r = 0; r < rows; ++r) {
      for(int c = 0; c < k; ++c) {
	T sum = 0;
	for(int i = 0; i < cols; ++i) {
	  sum += this[r, i] * rhs[i, c];
	}
	newMatrix.data[c + rows * r] = sum;
      }
    }
    return newMatrix;
  }
  
  auto opBinary(string op)(Mat!(T,rows,cols) rhs)
       if (op == `+` || op == `-`)
  {
    Mat!(T,rows,cols) newMatrix;
    const char[] sumation = "newMatrix.data[c + r * cols] = this[r,c]" ~ op ~ "rhs[r,c];";
    for(int r = 0; r < rows; ++r) {
      for(int c = 0; c < cols; ++c) {
	mixin(sumation);
      }
    }
    return newMatrix;
  }

  void setIndentity()
  in
  {
    assert((rows == cols), "rows and columns must be the same length for the function: Matrix.indentity()");
  }
  body
  {
    data[0 .. $] = 0;
    const size_t dim = rows | cols;
    for(int i = 0; i < dim; ++i) {
      data[i + i * rows] = 1;
    }
  }

  const string toString() {
    import std.format : format;
    
    template getType(T) {
      char isTFloating() {
	static if (isFloatingPoint!T)
	  return 'f';
	else return 'd';
      }
    }
    
    string output;
    immutable string formatString = "(%(%" ~ getType!T.isTFloating() ~ " %))\n";
    
    for(size_t rowIndex = 0; rowIndex < rows; ++rowIndex) {
      const size_t start = rowIndex * cols;
      const size_t end = start + cols;
      output ~= format(formatString,data[start .. end]);
    }
    return output;
  }
}

struct Point
{
  int x, y;

  float magnitude() {
    import std.math : sqrt;
    return sqrt(cast(float)(x ^^ 2 + y ^^ 2));
  }
  string toString() {
    import std.format : format;
    return format("(%d, %d)", x, y);
  }
}

alias Vec3f = Vector!(float, 3);
alias Vec4f = Vector!(float, 4);

alias Vec3i = Vector!(int, 3);
alias Vec4i = Vector!(int, 4);

alias Vec2f = Vector!(float, 2);
alias Vec2i = Vector!(int, 2);

alias Matrix4x4 = Mat!(float, 4, 4);
alias Matrix3x3 = Mat!(float, 3, 3);
alias Matrix4x1 = Mat!(float, 4, 1);
alias Matrix1x4 = Mat!(float, 1, 4);
alias Matrix2x2 = Mat!(float, 2, 2);

alias Trianglef = Triangle!(float);
alias Trianglei = Triangle!(int);


unittest
{
  Matrix4x4 a = {[1,2,3,4,
	          5,6,7,8,
		  9,10,11,12,
		  13,14,15,16]};
  Vec3f b = {[1,2,3]};
  auto c = a * b;

}
