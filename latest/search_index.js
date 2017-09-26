var documenterSearchIndex = {"docs": [

{
    "location": "index.html#",
    "page": "Home",
    "title": "Home",
    "category": "page",
    "text": ""
},

{
    "location": "index.html#Arrows.jl-1",
    "page": "Home",
    "title": "Arrows.jl",
    "category": "section",
    "text": "Arrows.jl is a differentiable programming environment implemented in Julia.  The goal is to combine the benefits of deep neural networks - namely, that they are differentiable, -  with the benefits of modern programming languages - recursion, modularity, higher-orderness, types. To do this, we build upon the formalism of Arrows."
},

{
    "location": "index.html#Installation-1",
    "page": "Home",
    "title": "Installation",
    "category": "section",
    "text": "Arrows is built in Julia but not yet in the official Julia Package repository.  You can still easily install it from a Julia repl with:Pkg.clone(\"https://github.com/zenna/Arrows.jl.git\")"
},

{
    "location": "select.html#",
    "page": "Selection",
    "title": "Selection",
    "category": "page",
    "text": ""
},

{
    "location": "select.html#Selection-1",
    "page": "Selection",
    "title": "Selection",
    "category": "section",
    "text": "Arrows has a few mechanisms to select Ports, SubPorts and various Arrow types. Arrows.jl embraces unicode! The following symbols are used throughout:▸ = in_port\n◂ = out_port\n▹ = in_sub_port\n◃ = out_sub_port\n⬧ = port\n⬨ = sub_port"
},

{
    "location": "select.html#Filtering-Examples-1",
    "page": "Selection",
    "title": "Filtering Examples",
    "category": "section",
    "text": "These can be used to select filtering by boolean combinations of predicates◂(arr, 1): The first out Port\n▹(sarr, is(θp)): all parametric in SubPorts\n◂(carr, is(ϵ) ∨ is(θp), 1:3): first 3 Ports which are error or parametric"
},

{
    "location": "types.html#",
    "page": "Types",
    "title": "Types",
    "category": "page",
    "text": ""
},

{
    "location": "types.html#Core-Types-1",
    "page": "Types",
    "title": "Core Types",
    "category": "section",
    "text": ""
},

{
    "location": "types.html#Arrows.AbstractArrow",
    "page": "Types",
    "title": "Arrows.AbstractArrow",
    "category": "Type",
    "text": "An Arrow of I inputs and O outputs\n\nSemantics of this model\n\nArrow\n\nThere are a finite number of primitive arrows, PrimArrow\nEach parr::PrimArrow is unique and uniquely identifiable by a name, globally\nThere are a finite number of composite arrows, CompArrow\nEach CompArrow is unique and uniquely identifiable by name(arr) globally\n\nPort\n\nAn Arrow has I and O input / output ports\nThese I+O Ports are the boundary ports of a CompArrow\nPorts are named name(port) and uniquely identifiable w.r.t. Arrow\nPorts on Arrow are ordered 1:I+O but  ordering is independent of whther is_in_port or is_out_port\n\nSubArrow\n\nA composite arrow contains a finite number of components: SubArrows\nEach SubArrow is unique and uniquely identifiable by name within its parent\nEach SubArrow contains a reference to another PrimArrow or CompArrow\nWe can dereference a SubArrow to retrieve the PrimArrow or CompArrow\nA SubPort is a port of SubArrow\nWe can dereference it to get the corresponding port on CompArrow / PrimArrow\na SubPort which is on a SubArrow is not a boundary\n\nValue\n\nAll Ports that are connected share the same Value\nOften it is useful to talk about these ValueSet individually\na Value is a set of Ports such that there exists an edge between each port ∈ Value, i.e. a weakly connected component\n\nTrace\n\nSubArrows can refer to CompArrow's, even the same CompArrow\nIn execution and other contexts, it is useful be refer to nested\n\n\n\n"
},

{
    "location": "types.html#Arrows.CompArrow",
    "page": "Types",
    "title": "Arrows.CompArrow",
    "category": "Type",
    "text": "A Composite Arrow: An Arrow composed of multiple Arrows\n\n\n\n"
},

{
    "location": "types.html#Arrow-Types-1",
    "page": "Types",
    "title": "Arrow Types",
    "category": "section",
    "text": "AbstractArrowCompArrowPrimArrow"
},

{
    "location": "types.html#Arrows.Port",
    "page": "Types",
    "title": "Arrows.Port",
    "category": "Type",
    "text": "An interface to an Arrow\n\n\n\n"
},

{
    "location": "types.html#Arrows.Props",
    "page": "Types",
    "title": "Arrows.Props",
    "category": "Type",
    "text": "Set of Properties\n\n\n\n"
},

{
    "location": "types.html#Ports-1",
    "page": "Types",
    "title": "Ports",
    "category": "section",
    "text": "PortProps"
},

{
    "location": "types.html#Arrows.SubArrow",
    "page": "Types",
    "title": "Arrows.SubArrow",
    "category": "Type",
    "text": "A component within a CompArrow\n\n\n\n"
},

{
    "location": "types.html#Arrows.SubPort",
    "page": "Types",
    "title": "Arrows.SubPort",
    "category": "Type",
    "text": "A Port on a SubArrow\n\n\n\n"
},

{
    "location": "types.html#SubTypes-1",
    "page": "Types",
    "title": "SubTypes",
    "category": "section",
    "text": "SubArrowSubPort"
},

{
    "location": "comparrow.html#",
    "page": "CompArrow API",
    "title": "CompArrow API",
    "category": "page",
    "text": ""
},

{
    "location": "comparrow.html#CompArrow-1",
    "page": "CompArrow API",
    "title": "CompArrow",
    "category": "section",
    "text": "A CompArrow of a data flow program is analogous to an abstract syntax tree of a program."
},

{
    "location": "comparrow.html#Arrows.sub_ports",
    "page": "CompArrow API",
    "title": "Arrows.sub_ports",
    "category": "Function",
    "text": "SubPorts on boundary of arr\n\n\n\nSubPorts connected to sarr\n\n\n\nPorts represented in val\n\n\n\n"
},

{
    "location": "comparrow.html#Construction-1",
    "page": "CompArrow API",
    "title": "Construction",
    "category": "section",
    "text": "sub_ports"
},

]}
