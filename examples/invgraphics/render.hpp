#pragma once

#include "boost/math/tools/promotion.hpp"
#include <fstream>
#include <iostream>

#include <tuple>
#include <memory>

using Eigen::Matrix;
using Eigen::Dynamic;

namespace RT {

// Type aliases
using Var = stan::math::var;
template <class T> using Vec = Matrix<T, Dynamic, 1>;
template <class T> using Point = Matrix<T, Dynamic, 1>;

// Linearly interpolate between `a` and `b`
template <typename T>
T mix(T a, T b, double mix) {return b * mix + a * (1 - mix);}

template <typename T>
Vec<T> Vec3(T x) {Vec<T> v(3); v << x, x, x; return v;}

template <typename T>
Vec<T> Vec3(T x, T y, T z) {Vec<T> v(3); v << x, y, z; return v;}

//Normalize a vector so that its length is 1.0
template <typename T>
Vec<T> normalize(const Vec<T> & x) {
  T factor = stan::math::dot_self(x);
  T sqrted = sqrt(factor);
  return stan::math::divide(x, sqrted);
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
// opt1. template the shape and make it aubtype of a bigger untemplated set
// opt2. just return a booleam, and modify the values

template <typename T>
struct Sphere {
public:
  Point<T> center;              // position of the sphere
  T radius;                     // radius
  Vec<T> surface_color;         // surfae colour
  T reflection;
  T transparency;
  Vec<T> emission_color;        // light
};

template <typename T1, typename T2>
Intersection<typename boost::math::tools::promote_args<T1, T2>::type>
rayintersect(const Ray<T2, T2> &r, const Sphere<T1> &s) {
  using VarType = typename boost::math::tools::promote_args<T1, T2>::type;
  Vec<VarType> l = s.center - r.orig;
  VarType tca = stan::math::dot_product(l, r.dir);
  VarType radius2 = pow(s.radius, 2.0);

  if (tca < 0) {
    // return Intersection(false, 0.0, 0.0);
    // return false;
    return Intersection<VarType>{tca, 0.0, 0.0};
  }
  VarType d2 = stan::math::dot_product(l,l) - tca * tca;
  if (d2 > radius2) {
    // return (false, 0.0, 0.0);
    // return false;
    return Intersection<VarType>{radius2 - d2, 0.0, 0.0};
  }

  VarType thc = sqrt(radius2 - d2);
  VarType t0 = tca - thc;
  VarType t1 = tca + thc;
  // return true;

  return Intersection<VarType>{radius2 - d2, t0, t1};
}

template <typename T>
T rlu(T x) {if (x > 0.0) {return x;} else {T y = 0.0; return y;}}

// FIXME return type
template <typename T, typename T2>
Vec<typename boost::math::tools::promote_args<T, T2>::type> trace(
  const Ray<T, T> &r,
  const std::vector<Sphere<T2>> &spheres,
  int depth) {
  // std::cout << "ray" << r.dir << "," << r.orig << std::endl;

  using VarType = typename boost::math::tools::promote_args<T, T2>::type;

  bool areintersections = false;
  VarType tnear = INFINITY;
  const Sphere<T2>* sphere = NULL;

  // find intersection of this ray with the sphere in the scene
  for (unsigned i = 0; i < spheres.size(); ++i) {
    double t0 = INFINITY, t1 = INFINITY;
    Intersection<VarType> inter = rayintersect(r, spheres[i]);
    if (inter.doesintersect > 0) {
      if (inter.t0 < 0) inter.t0 = t1;
      if (inter.t0 < tnear) {
          tnear = inter.t0;
          sphere = &spheres[i];
          // std::cout << "best is" << i << std::endl;
      }
    }
  }

  // std::cout << "checkedallspheres\n" << std::endl;

  if (!sphere) {
    VarType one = 1.0;
    return Vec3(one);
  }

  // std::cout << "tnear:" << tnear << std::endl;
  // std::cout << "spherecenter:" << sphere->center << std::endl;


  VarType zero = 0.0;
  Vec<VarType> surface_color = Vec3(zero);        // color of the ray/surfaceof the object intersected by the ray
  Vec<VarType> phit = r.orig + r.dir * tnear; // point of intersection
  // @show r.orig, r.dir, tnear
  Vec<VarType> nhit = phit - sphere->center;   // normal at the intersection point
  nhit = normalize(nhit);        // normalize normal direction

  // # If the normal and the view direction are not opposite to each other
  // # reverse the normal direction. That also means we are inside the sphere so set
  // # the inside bool to true. Finally reverse the sign of IdotN which we want
  // # positive.
  // bias = 1e-4;   # add some bias to the point from which we will be tracing
  double bias = 0.0001;
  bool inside = false;
  // std::cout << "dot" << stan::math::dot_product(r.dir, nhit) << std::endl;

  if (stan::math::dot_product(r.dir, nhit) > 0.0) {
    nhit = -nhit;
    inside = true;
  }

  if ((sphere->transparency > 0.0 || sphere->reflection > 0.0) && depth < 1) {
    Vec<VarType> minusrdir = r.dir * -1.0;
    VarType facingratio = stan::math::dot_product(minusrdir, nhit);
    // # change the mix value to tweak the effect
    VarType one = 1.0;
    VarType fresneleffect = mix(pow((1.0 - facingratio),3), one, 0.1);
    // # @show facingratio, fresneleffect, -r.dir, nhit
    // # compute reflection direction (not need to normalize because all vectors
    // # are already normalized)
    Vec<VarType> refldir = r.dir - nhit * 2 * stan::math::dot_product(r.dir, nhit);
    refldir = normalize(refldir);
    Vec<VarType> reflection = trace(Ray<VarType, VarType>{phit + nhit * bias, refldir}, spheres, depth + 1);
    // auto refraction = Vec3(zero)

    // # the result is a mix of reflection and refraction (if the sphere is transparent)
    Vec<VarType> prod = reflection * fresneleffect;
    surface_color = stan::math::elt_multiply(prod, sphere->surface_color);
  }
  else {
    // # it's a diffuse object, no need to raytrace any further
    for (int i = 0; i<spheres.size(); ++i) {
      if (spheres[i].emission_color[1] > 0) {
        // # this is a light
        double transmission = 1.0;
        Vec<VarType> lightDirection = spheres[i].center - phit;
        lightDirection = normalize(lightDirection);

        for (int j = 0; j < spheres.size(); ++j) {
          if (i != j) {
            // # error("Here's an error")
            Ray<VarType, VarType> r2{phit + nhit * bias, lightDirection};
            Intersection<VarType> inter = rayintersect(r2, spheres[j]);
            if (inter.doesintersect > 0) {
              transmission = 0.0;
            }
          }
        }
        Vec<VarType> lhs = sphere->surface_color * transmission * rlu(stan::math::dot_product(nhit, lightDirection));
        surface_color += stan::math::elt_multiply(lhs, spheres[i].emission_color);
      }
    }
  }
  return surface_color + sphere->emission_color;
}

// Render an image
template <typename T>
std::vector<Vec<T>> render(const std::vector<Sphere<T>> &spheres) {
  int width = 480;
  int height = 320;
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
      T xx = (2 * ((x + 0.5) * inv_width) - 1) * angle * aspectratio;
      T yy = (1 - 2 * ((y + 0.5) * inv_height)) * angle;
      T minus1 = -1.0;
      Vec<T> raydir = normalize(Vec3(xx, yy, minus1));
      T zero = 0.0;
      // std::cout << x << "," << y << std::endl;
      image[pixel] = trace(Ray<T, T>{Vec3(zero), raydir}, spheres, 0);
    }
  }
  return image;
}

Matrix<double, Dynamic, 1> realize(const std::vector<Sphere<double>> &spheres) {
  int nsphereparams = 10;
  int numpoitns = nsphereparams * spheres.size();
  std::cout << numpoitns << "Num points" << std::endl;
  Matrix<double, Dynamic, 1> flatspheres(nsphereparams * spheres.size());
  int j = 0;
  for (auto const &sphere : spheres) {
    flatspheres[j++] = sphere.center[0];
    std::cout << "j:" << j << std::endl;
    flatspheres[j++] = sphere.center[1];
    std::cout << "j:" << j << std::endl;
    flatspheres[j++] = sphere.center[2];
    std::cout << "j:" << j << std::endl;
    flatspheres[j++] = sphere.radius;
    std::cout << "j:" << j << std::endl;
    flatspheres[j++] = sphere.surface_color[0];
    std::cout << "j:" << j << std::endl;
    flatspheres[j++] = sphere.surface_color[1];
    std::cout << "j:" << j << std::endl;
    flatspheres[j++] = sphere.surface_color[2];
    std::cout << "j:" << j << std::endl;
    flatspheres[j++] = sphere.reflection;
    std::cout << "j:" << j << std::endl;
    flatspheres[j++] = sphere.transparency;
    std::cout << "j:" << j << std::endl;
    flatspheres[j++] = sphere.emission_color[0];
}

  return flatspheres;
}

double v(stan::math::var x) {return x.val();}
double v(double x) {return x;}

template <typename T>
void drawtofile(std::string fname, std::vector<Vec<T>> image, int width, int height) {
    // Save result to a PPM image (keep these flags if you compile under Windows)
  std::ofstream ofs(fname, std::ios::out | std::ios::binary);
  ofs << "P6\n" << width << " " << height << "\n255\n";
  for (unsigned i = 0; i < width * height; ++i) {
      ofs << (unsigned char)(std::min(1.0, v(image[i][0])) * 255) <<
             (unsigned char)(std::min(1.0, v(image[i][1])) * 255) <<
             (unsigned char)(std::min(1.0, v(image[i][2])) * 255);
  }
  ofs.close();
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
    std::vector<Sphere<T>> spheres;
    for (int i = 0; i < xs.size(); i+=nsphereparams) {

      Sphere<T> sphere{Vec3(xs[i],xs[i+1],xs[i+2]),xs[i+3],
        Vec3(xs[i+4], xs[i+5], xs[i+6]), xs[i+7], xs[i+8], Vec3(xs[i+9])};
      spheres.push_back(sphere);
    }

    std::cout << "Rendering with gradient" << std::endl;
    std::vector<Vec<T>> img = render<T>(spheres);

    T diff = 0.0;
    for (int i = 0; i < width*height; ++i) {
      T dist = img[i][0] - observation[i][0];
      diff += dist * dist;

      dist = img[i][1] - observation[i][1];
      diff += dist * dist;

      dist = img[i][1] - observation[i][1];
      diff += dist * dist;
    }

    return diff;
  }
};

}
