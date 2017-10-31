using Base.Test
using Arrows
import Arrows.BenchmarkArrows: STD_ROTATION_MATRIX, render, smallmodelnet, randslice
using NamedTuples

fakevoxels(batch_size) = rand(batch_size, 32, 32, 32)
opt = @NT(width = 128, height = 128, nsteps = 15, res = 32, batch_size = 10,
          phong = false, density = 2)

"Test construction of render array that takes voxel_grid"
function test_array_arrow(opt)
  carr = CompArrow(:render, [:voxel], [:img])
  voxels, img = ⬨(carr)
  img_sprt = render(voxels, STD_ROTATION_MATRIX, opt)
  link_ports!(img_sprt, img)
  carr
end

test_array_arrow(opt)

function test_array_render_arrow(voxels = smallmodelnet())
  rendercarr = test_array_arrow()
  i = rand(1:10)
  img = rendercarr(voxels)
end

test_array_render_arrow(fakevoxels(10))

function tfapply(intens, outtens, args, sess=TensorFlow.Session())
  TensorFlow.run(sess, TensorFlow.global_variables_initializer())
  run(sess, outtens, Dict(zip(intens, args)))
end

"Test TensorFlow render"
function test_tf_render(opt, voxels = smallmodelnet())
  rendercarr = test_array_arrow(opt)
  tfrender = Arrows.TensorFlowTarget.Graph(rendercarr)
  voxels = smallmodelnet()
  sess = TensorFlow.Session(tfrender.graph)
  outimg = tfapply(tfrender.in, tfrender.out, [randslice(10, voxels)], sess)
end

test_tf_render(opt, fakevoxels(10))

"Test native julia render"
function test_render(opt, voxels = smallmodelnet())
  imgs = render(voxels, STD_ROTATION_MATRIX, opt)
  img = reshape(imgs[1,:,:], (128, 128))
end

test_render(opt, fakevoxels(10))

"Test inversion of render arrow"
function test_inv_array_arrow()
  carr = test_array_arrow()
  invcarr = invert(carr)
end

test_inv_array_arrow()

function test_arrow_render()
  # Render only uses a small subset of the input.
  # Therefore, we need to execute it twice: once to know which are the
  # relevant inputs, and the second time to actually compute the arrows
  nvox▹ = opt.batch_size * opt.res * opt.res * opt.res
  ◃nvox = opt.batch_size * opt.width * opt.height
  probe = CompArrow(:probe, nvox▹, ◃nvox);
  vox_probe▹ = reshape(▹(probe), (opt.batch_size, opt.res, opt.res, opt.res));
  vox_probe▹ = render(vox_probe▹, STD_ROTATION_MATRIX, opt);
  vox_probe▹ = reshape(vox_probe▹, ◃nvox)

  non_undef = find(Arrows.is_src, ▹(probe))
  varr = CompArrow(:render, length(non_undef), ◃nvox);
  vox▹ = Array{Any}(nvox▹);

  for (id, sport) in zip(non_undef, ▹(varr))
      vox▹[id] = sport;
  end
  vox▹ = reshape(vox▹, (opt.batch_size, opt.res, opt.res, opt.res));
  vox◃ = render(vox▹, STD_ROTATION_MATRIX, opt);
  vox◃ = reshape(vox◃, ◃nvox);
  for (id, sport) in enumerate(vox◃)
    sport ⥅ (varr, id)
  end
  varr
end

function test_arrows_array(opt)
  nvox▹ = opt.batch_size * opt.res * opt.res * opt.res
  ◃nvox = opt.batch_size * opt.width * opt.height
  carr = CompArrow(:probe, [:voxel], [:img])
end

test_arrows_array(opt)
