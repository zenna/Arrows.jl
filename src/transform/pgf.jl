"Attach the prefix pgf_ to the name of the arrow."
pgf_rename!(carr::CompArrow) = (rename!(carr, Symbol(:pgf_, carr.name)); carr)

"Outer method that connects the loose ports and renames the arrow."
pgf_out = pgf_rename! ∘ (carr -> link_to_parent!(carr, loose ∧ should_src))

"Inner method that will replace all the subarrows with their respective pgfs."
pgf(parr::PrimArrow, const_in) = parr

function pgfreplace(carr::CompArrow, sarr::SubArrow, tparent::TraceParent,
                    abtvals::TraceAbVals; pgf=pgf)
  pmap = id_portid_map(carr)
  pgf_out(carr), pmap
end

function pgfreplace(parr::PrimArrow, sarr::SubArrow, tparent::TraceParent,
                    abtvals::TraceAbVals; pgf=pgf)
  idabvals = tarr_idabv(TraceSubArrow(tparent, sarr), abtvals)
  pgf(parr, const_in(parr, idabvals)), id_portid_map(parr)
end

"""Construct a parameter generating function (pgf) of carr
# Args:
  - carr: the arrow to tranform
# Returns:
  A parameter generating function of carr that for a given input x outputs
  the corresponding value y as well as θ such that f^(-1)(y;θ) = x."""
function pgf(arr::CompArrow,
             inner_pgf=pgf,
             sprtabvals::SprtAbVals = SprtAbVals())
  arr = duplify(arr)
  sprtabvals = SprtAbVals(⬨(arr, sprt.port_id) => abvals for (sprt, abvals) in sprtabvals)
  abvals = traceprop!(arr, sprtabvals)
  custpgfreplace = function (arr, sarr, tparent, abtvals)
                    pgfreplace(arr, sarr, tparent, abtvals; pgf=inner_pgf)
                  end
  tracewalk(custpgfreplace, arr, abvals)[1]
end

pgf(arr::CompArrow, inner_pgf, nmabv::NmAbVals) =
  pgf(arr, inner_pgf, sprtabv(arr, nmabv))


"Cannot construct PGF"
struct PgfError <: Exception
  arr::Arrow
  abv::XAbVals
end

Base.showerror(io::IO, e::PgfError) =
  print(io, "Cannot construct pgf: $(e.arr) with values $(e.abv)")
