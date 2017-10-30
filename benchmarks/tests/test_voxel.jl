using Arrows
import Arrows.BenchmarkArrows: STD_ROTATION_MATRIX, render
using NamedTuples
import util: smallvoxels

function test_array_arrow()
  carr = CompArrow(:render, [:voxel], [:img])
  voxels, img = ⬨(carr)
  opt = @NT(width = 256, height = 256, nsteps = 10, res = 32, batch_size = 10,
            phong = false, density = 2)

  img_sprt = render(voxels, STD_ROTATION_MATRIX, opt)
  link_ports!(img_sprt, img)
  carr
end


function test_array_render_arrow()
  rendercarr = test_array_arrow()
  @show x = rand(1:64)
  img = carr(smallvoxels[x:x+1, :, :, :])
end

function tfapply(intens, outtens, args, sess=TensorFlow.Session())
  TensorFlow.run(sess, TensorFlow.global_variables_initializer())
  run(sess, outtens, Dict(zip(intens, args)))
end

function test_tf_render()
  rendercarr = test_array_arrow()
  tfrender = Arrows.TensorFlowTarget.Graph(rendercarr)
  voxels = smallmodelnet()
  sess = TensorFlow.Session(tfrender.graph)
  outimg = tfapply(tfrender.in, tfrender.out, [randslice(10, voxels)], sess)
end

function test_render(voxels = modelnet())
  opt = @NT(width = 256, height = 256, nsteps = 15, res = 32, batch_size = 1,
            phong = false, density = 2)
  x = rand(1:size(voxels, 1) - opt.batch_size)
  voxels = voxels[x:x+opt.batch_size-1, :, :, :]
  imgs = render(voxels, STD_ROTATION_MATRIX, opt)
  img = reshape(imgs[1,:,:], (256, 256))
  colorview(Gray, img)
end

function test_inv_array_arrow()
  carr = test_array_arrow()
   # Hack until constant propagation is done
  function subinv(sarr::Arrows.SubArrow)
    carr = deref(sarr)
    const_in = map(Arrows.is_src_source, ▹(sarr))
    subinv(sarr, deref(sarr), const_in)
  end
  subinv(sarr::Arrows.SubArrow, arr::Arrow, const_in) = inv(arr, const_in)
  function subinv(sarr::Arrows.SubArrow, ::Arrows.ReshapeArrow, const_in::Vector{Bool})
    @show const_in
    carr = CompArrow(:inv_reshape, [:x], [:z])
    @show x, z = get_ports(carr)
    @show src = add_sub_arr!(carr, SourceArrow((1, 32, 32, 32)))
    @show reshp = add_sub_arr!(carr, Arrows.ReshapeArrow())
    @show link_ports!(x, (reshp, 1))
    @show link_ports!((src, 1), (reshp, 2))
    @show link_ports!((reshp, 1), z)
    @assert is_wired_ok(carr)
    carr, Dict(1=>1, 3=>2, 3=>2)
  end
  function subinv(sarr::Arrows.SubArrow, ::Arrows.GatherNdArrow, const_in::Vector{Bool})
    v = deref(sub_arrow(Arrows.in_neighbors(▹(sarr, 2))[1])).value
    @show size(v)
    # @show Arrows.in_neighbors.(▹(sarr))
    @assert false
  end
  invcarr = invert(carr, subinv)
end

test_inv_array_arrow()
# import Images: colorview, Gray

function test_render(voxels = modelnet())
  opt = @NT(width = 256, height = 256, nsteps = 15, res = 32, batch_size = 8,
            phong = false, density = 2)
  x = rand(1:size(voxels, 1) - opt.batch_size)
  voxels = voxels[x:x+opt.batch_size-1, :, :, :]
  imgs = render(voxels, STD_ROTATION_MATRIX, opt)
  img = reshape(imgs[1,:,:], (256, 256))
  colorview(Gray, img)
end

function test_arrow_render()
  # Render only uses a small subset of the input.
  # Therefore, we need to execute it twice: once to know which are the
  # relevant inputs, and the second time to actually compute the arrows
  opt = @NT(width = 32, height = 32, nsteps = 3, res = 32, batch_size = 1,
            phong = false, density = 2)
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

function test_arrows_array()
  opt = @NT(width = 32, height = 32, nsteps = 3, res = 32, batch_size = 1,
            phong = false, density = 2)
  nvox▹ = opt.batch_size * opt.res * opt.res * opt.res
  ◃nvox = opt.batch_size * opt.width * opt.height
  carr = CompArrow(:probe, [:voxel], [:img])
end

# @time varr = test_arrow_render();
# println("length(sub_arrows(varr)): $(length(sub_arrows(varr)))")
# println("testing if it's wired ok")
# @time is_wired_ok(varr)
# println("computing inverse")
# @time invvarr = invert(varr);
# println("inverse computed")
# # end
