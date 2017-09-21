#include <nlopt.hpp>

namespace RT {

using Eigen::Matrix;
using Eigen::Dynamic;

using Image = std::vector<Vec<double>>;

std::vector<double> to_stl_vec(const Vec<double> &x) {
  std::vector<double> out(x.size());
  for (int i = 0; i<x.size(); ++i) {
    out[i] = x[i];
  }
  return out;
}

template <typename T>
std::vector<Sphere<double>> to_spheres(const T &x) {
  int nparamspersphere = 10;
  std::vector<Sphere<double>> spheres;
  std::vector<double> out(x.size());
  for (int i = 0; i<x.size(); i+=nparamspersphere) {
    spheres.push_back(Sphere<double>{Vec3(x[i], x[i+1], x[i+2]), x[i+3], Vec3(x[i+4], x[i+5], x[i+6]), x[i+7], x[i+8], Vec3(x[i+9])});
  }
  return spheres;
}


class ObjF {
public:
  ImgDiff f;
  int i = 0;

  double operator()(const std::vector<double> &x, std::vector<double> &grad) {
    double fx;
    Matrix<double, Dynamic, 1> eigenx(x.size());
    for (int i = 0; i < x.size(); ++i) {
      eigenx[i] = x[i];
    }

    Matrix<double, Dynamic, 1> grad_fx(x.size());
    stan::math::gradient(f, eigenx, fx, grad_fx);

    if (!grad.empty()) {
      std::vector<double> grad_vec = to_stl_vec(grad_fx);
      for (int i = 0; i < x.size(); ++i) {
        grad[i] = grad_vec[i];
      }
    }

    // Put grad stuff into vector
    std::string fname ="iter";
    fname.append(std::to_string(i));
    fname.append(".ppm");
    RT::drawtofile(fname, render<double>(to_spheres(x)), 480,320);

    std::string gradfname ="graditer";
    gradfname.append(std::to_string(i));
    gradfname.append(".ppm");
    RT::drawtofile(gradfname, render<double>(to_spheres(grad)), 480,320);

    std::cout << "fx:" << fx << std::endl;
    ++i;
    return fx;
  }

  static double wrap(const std::vector<double> &x, std::vector<double> &grad, void *data) {
    return (*reinterpret_cast<ObjF*>(data))(x, grad); }
};

void optimize(const Image &observation, const std::vector<Sphere<double>> &init_spheres) {
  int ww = 480;
  int hh = 320;
  RT::ImgDiff f(ww, hh, observation);
  Vec<double> sceneparams = realize(init_spheres);
  std::vector<double> initip = to_stl_vec(sceneparams);

  std::cout << "Nparams : " << initip.size() << std::endl;

  nlopt::opt opt(nlopt::LN_COBYLA, initip.size());
  // nlopt::opt opt(nlopt::LN_MMA, initip.size());


  // Set bounds
  ObjF objfunc{f};
  opt.set_min_objective(ObjF::wrap, &f);
  opt.set_xtol_rel(1e-4);

  // Set initial state as x

  double minf;
  RT::drawtofile("beforeopt.ppm", render<double>(to_spheres(initip)), ww,hh);
  std::cout << "Starting Optimization" << std::endl;
  nlopt::result result = opt.optimize(initip, minf);
  std::cout << "Minimum found at:" << minf << std::endl;
  RT::drawtofile("afteropt.ppm", render<double>(to_spheres(initip)), ww,hh);
}

}
