#pragma once

// The issue is that when we have a collection of mixed types like this, we store
// A pointer to its base class.  But the intersection point depends on whether
// The ray is a var or the sphere is a var
// But its problematic because we dont know if the sphere is a ray
// KISS use vector<

#include <tuple>
#include <memory>

using Eigen::Matrix;
using Eigen::Dynamic;

namespace RT {

using Var = stan::math::var;

// Types
template <class T> using Vec = Matrix<T, Dynamic, 1>;
template <class T> using Point = Matrix<T, Dynamic, 1>;

// Linearly interpolate between `a` and `b`
template <typename T>
T mix(T a, T b, T mix) {return b * mix + a * (1 - mix);}

template <typename T>
Vec<T> Vec3(T x) {Vec<T> v(3); v << x, x, x; return v;}

template <typename T>
Vec<T> Vec3(T x, T y, T z) {Vec<T> v(3); v << x, y, z; return v;}

//Normalize a vector so that its length is 1.0
template <typename T>
Vec<T> normalize(const Vec<T> & x) {
  T factor = stan::math::dot_self(x);
  return stan::math::divide(x, factor);
}

template <typename T>
struct Intersection {
public:
  T doesintersect;
  T t0;
  T t1;
};

// Parameteric Ray.  r(t) = o + td   0 ≤ t ≤ ∞
template <typename T1, typename T2>
struct Ray {
  Vec<T1> orig;
  Vec<T2> dir;
};

// The return type depends on whether the sphere is a var/double and whether ray is
// But we cant template the return type
//  opt1. templat the shape and make it aubtype of a bigger untemplated set
// opt2. just return a booleam, and modify the values


class Shape {
public:
  virtual bool rayintersect(const Ray<double,double> &r, double &t0, double &t1) const = 0;
  virtual bool rayintersect(const Ray<Var, Var> &r, Var &t0, Var &t1) const = 0;
  virtual ~Shape(){}
};

using ShapePtr = std::shared_ptr<Shape>;

template <typename T>
struct Sphere : public Shape {
public:
  Point<T> center;              // position of the sphere
  T radius;                     // radius
  Vec<T> surface_color;         // surfae colour
  T reflection;
  T transparency;
  Vec<T> emission_color;        // light

  Sphere(Point<T> c, T r, Vec<T> s, T re, T t, Vec<T> e) :
    center(c), radius(r), surface_color(s), reflection(re), transparency(t), emission_color(e) {}

  template <typename T2>
  bool rayintersect(const Ray<T2, T2> &r, T &t0, T &t1) const {
    Vec<T> l = center - r.orig;
    T tca = stan::math::dot_product(l, r.dir);
    T radius2 = pow(radius, 2.0);

    if (tca < 0) {
      // return Intersection(false, 0.0, 0.0);
      return false;
      // return Intersection<double>{tca, 0.0, 0.0};
    }
    T d2 = stan::math::dot_product(l,l) - tca * tca;
    if (d2 > radius2) {
      // return (false, 0.0, 0.0);
      return false;
      // return Intersection<double>{radius2 - d2, 0.0, 0.0};
    }

    T thc = sqrt(radius2 - d2);
    t0 = tca - thc;
    t1 = tca + thc;
    return true;

    // return Intersection<double>{radius2 - d2, t0, t1};
  }

  //
  // Intersection<Var> rayintersect(const Ray<Var, Var> &r) const {
  //   Vec<Var> l = center - r.orig;
  //   Var tca = stan::math::dot_product(l, r.dir);
  //   Var radius2 = pow(radius, 2.0);
  //
  //   if (tca < 0) {
  //     // return Intersection(false, 0.0, 0.0);
  //     return Intersection<Var>{tca, 0.0, 0.0};
  //   }
  //   Var d2 = stan::math::dot_product(l,l) - tca * tca;
  //   if (d2 > radius2) {
  //     // return (false, 0.0, 0.0);
  //     return Intersection<Var>{radius2 - d2, 0.0, 0.0};
  //   }
  //
  //   Var thc = sqrt(radius2 - d2);
  //   Var t0 = tca - thc;
  //   Var t1 = tca + thc;
  //
  //   return Intersection<Var>{radius2 - d2, t0, t1};
  // }

};

using DoubleSphere = Sphere<double>;

// FIXME return type
template <typename T>
Vec<T> trace(
  const Ray<T, T> &r,
  const std::vector<ShapePtr> &spheres,
  int depth) {

  bool areintersections = false;
  double tnear = INFINITY;
  const Shape* sphere = NULL;

  auto t0; //= new(T);
  auto t1; //= new(T);
  // find intersection of this ray with the sphere in the scene
  for (unsigned i = 0; i < spheres.size(); ++i) {
    double t0 = INFINITY, t1 = INFINITY;
    bool inter = spheres[i]->rayintersect(r, t0, t1);
    if (inter.doesintersect) {
      if (inter.t0 < 0) inter.t0 = t1;
      if (inter.t0 < tnear) {
          tnear = inter.t0;
          sphere = &(*spheres[i]);
      }
    }
  }

  if (!sphere) {
    std::cout << "1" << std::endl;
    return Vec3(1.0);
  }
  else {
    std::cout << "0" << std::endl;
    return Vec3(0.0);
  }
}

// Render an image
template <typename T>
std::vector<Vec<T>> render(const std::vector<ShapePtr> &spheres) {
  int width = 640;
  int height = 480;
  std::vector<Vec<T>> image(width * height);
  double inv_width = 1/double(width);
  double inv_height = 1/double(height);
  double fov = 30.0;
  double aspectratio = width / double(height);
  double angle = tan(M_PI * 0.5 * fov / 180.);

  unsigned pixel = 0;
  for (unsigned y = 0; y < height; ++y) {
    for (unsigned x = 0; x < width; ++x, ++pixel) {
      // Generate Primary Ray
      double xx = (2 * ((x + 0.5) * inv_width) - 1) * angle * aspectratio;
      double yy = (1 - 2 * ((y + 0.5) * inv_height)) * angle;
      Vec<T> raydir = normalize(Vec3(xx, yy, -1.0));
      image[pixel] = trace(Ray<T, T>{Vec3(0.0), raydir}, spheres, 0);
    }
  }
  return image;
}

std::vector<Vec<double>> gen_img() {
  std::vector<ShapePtr> spheres;
  spheres.push_back(std::move(std::make_shared<DoubleSphere>(Vec3( 0.0,      0., -20.),     4., Vec3(1.00, 0.32, 0.36), 1., 0.5, Vec3(0.0))));
  spheres.push_back(std::move(std::make_shared<DoubleSphere>(Vec3( 0.0,      0., -20.),     4., Vec3(1.00, 0.32, 0.36), 1., 0.5, Vec3(0.0))));
  spheres.push_back(std::move(std::make_shared<DoubleSphere>(Vec3( 5.0,     -1., -15.),     2., Vec3(0.90, 0.76, 0.46), 1., 0.0, Vec3(0.0))));
  spheres.push_back(std::move(std::make_shared<DoubleSphere>(Vec3( 5.0,      0., -25.),     3., Vec3(0.65, 0.77, 0.97), 1., 0.0, Vec3(0.0))));
  spheres.push_back(std::move(std::make_shared<DoubleSphere>(Vec3(-5.5,      0., -15.),     3., Vec3(0.90, 0.90, 0.90), 1., 0.0, Vec3(0.0))));
  // // # light
  spheres.push_back(std::move(std::make_shared<DoubleSphere>(Vec3( 0.0,     20., -30.),     3., Vec3(0.00, 0.00, 0.00), 0., 0.0, Vec3(20.))));
  return render<double>(spheres);
}

struct ImgDiff {
  int width;
  int height;
  std::vector<Vec<double>> observation;

  ImgDiff(int w, int h, const std::vector<Vec<double>> & o) :
    width(w), height(h), observation(o) {}

  template <typename T>
  const T operator()(const Matrix<T, Dynamic, 1>  &xs) const {
    int nsphereparams = 10;
    int nspheres = xs.size() / nsphereparams;
    std::vector<ShapePtr> spheres;
    for (int i = 0; i < xs.size(); i+=nsphereparams) {
      auto sphere = std::make_shared<Sphere<T>>(Vec3(xs[i],xs[i+1],xs[i+2]),xs[i+3],
        Vec3(xs[i+4], xs[i+5], xs[i+6]), xs[i+7], xs[i+8], Vec3(xs[i+9]));
      spheres.push_back(std::move(sphere));
    }

    std::vector<Vec<T>> img = render<T>(spheres);

    // Reshape
    Matrix<T, Dynamic, Dynamic> rendered_img(width, height);
    int i = 0;
    for (int m = 0; m < width; ++m) {
      for (int n = 0; n < height; ++n) {
        std::cout << "m,n = " << m << " " << n << std::endl;
        rendered_img(m,n) = xs(i++);
      }
    }

    return stan::math::squared_distance(xs, stan::math::to_row_vector(observation));
  }
};

}
