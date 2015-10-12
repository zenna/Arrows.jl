#include <cmath>
#include <boost/math/constants/constants.hpp>
#include <stan/math.hpp>
#include "render.hpp"
#include "optimize.hpp"

using Eigen::Matrix;
using Eigen::Dynamic;

int main() {
  std::vector<RT::Vec<double>> imgdata = RT::gen_img();
  std::vector<RT::Sphere<double>> init_spheres = RT::gen_spheres2();
  RT::drawtofile("initial.ppm", imgdata, 480,320);

  RT::optimize(imgdata, init_spheres);
} 

  //
  // int main() {
  //   double fx;
  //   Matrix<double, Dynamic, 1> grad_fx;
  //
  //   // auto x = Eigen::VectorXd::Random(10);
  //   auto x = RT::realize(RT::gen_spheres2());
  //   std::cout << "x" << x << std::endl;
  //
  //   std::vector<Vec<double>> imgdata = gen_img();
  //   RT::drawtofile(imgdata, 640,480);
  //   RT::ImgDiff f(640, 460, imgdata);
  //   stan::math::gradient(f, x, fx, grad_fx);
  //   std::cout << "f(x) is: " << fx << " grad is: " << grad_fx << std::endl;
  //
  //   // for (const auto &g : grad_fx) {
  //   //   std::cout << g << std::endl;
  //   // }
  //
  // }
  //
