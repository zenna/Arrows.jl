#include <cmath>
#include <boost/math/constants/constants.hpp>
#include <stan/math.hpp>
#include "render.hpp"
#include <tuple>

using Eigen::Matrix;
using Eigen::Dynamic;

using namespace RT;

int main() {
  Eigen::MatrixXd data = Eigen::MatrixXd::Random(3,3);
  std::cout << "data" << data << std::endl;

  double fx;
  Matrix<double, Dynamic, 1> grad_fx;

  auto x = Eigen::VectorXd::Random(9);
  std::cout << "x" << x << std::endl;

  std::vector<Vec<double>> imgdata = gen_img();
  RT::ImgDiff f(3, 3, imgdata);
  stan::math::gradient(f, x, fx, grad_fx);
  std::cout << "f(x) is: " << fx << " grad is: " << grad_fx[0] << std::endl;

}
