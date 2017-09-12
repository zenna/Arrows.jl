"Asserts that its input is `true`"
struct AssertArrow <: PrimArrow end
name(::AssertArrow) = :fakeassert
port_props(::AssertArrow) =  [PortProps(true, :x, Bool)]

"Assert that a Boolean SubPort is True"
assert!(sport::SubPort) =
    link_ports!(sport, (add_sub_arr!(parent(sport), AssertArrow()), 1))

fakeassert(x) = ()
