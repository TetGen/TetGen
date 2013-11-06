# TetGen: Release Notes

## Version 1.5.0 (November 4, 2013)

-   Improved the efficiency of the mesh data structure
    (tetrahedron-based).
-   Implemented a new edge flip algorithm that does recursive
    combination of elementary flips.
-   Improved the Bowyer-Watson point insertion algorithm for robustness
    and efficiency.
-   Implemented a new algorithm for boundary recovery (the -Y option).
-   Implemented Shewchuk\'s CDT flip algorithm (the -p option).
-   Implemented a new Delaunay refinement algorithm (the -q option) for
    handling small input angles (sharp features).
-   Fully supports isolated input segments and with segment markers
    (which do not attach to any facet).
-   Many new options and parameters for improving mesh quality and mesh
    optimization.

## Version 1.4.3 (September 6, 2009)

-   A new implementation of the Bowyer-Watson algorithm for Delaunay
    tetrahedralization. It is generally faster than the incrmental flip
    algorithm. From my tests, the flip algorithm usually constructs
    about twice (or more) as many intermediate tetrahedra as B-W
    algorithm. Now B-W algorithm is the default algorithm for Delaunay
    tetrahedralization.
-   A new implementaton of the constrained Delaunay tetrahedralization
    algorithm (the -p option).
-   A new implementation of the Steiner point removal algorithm (the -Y
    option).
-   Improved the implementation of the constrained Delaunay refinement
    algorithm (the -q option).
-   Add the minimum dihedral angle of tetrahedra as the tetrahedral
    shape quality parameter (set after -qq option). The minimum dihedral
    angle is made the major mesh quality measure now. Default it is 5
    degree. One can increase it as larger as 18 degree. The radius-edge
    ratio (set after -q option) is still in use.\
    For an example, the string \'-q1.4q10\' sets both a radius-edge
    ratio (\<= 1.4) and a minimum dihedral angle (\>= 10 degree) as the
    tetrahedral shape quality measure.
-   Support the read and write of the legacy VTK file format which can
    be visualized by Paraview (see .vtk file format and -K option).


## Version 1.4.2 (April 16, 2007)

-   Improved the constrained Delaunay mesh refinement algorithm. Slivers
    (very flat tetrahedra) are removed during the mesh refinement. For
    geometries having no input angle and dihedral angle smaller than 60
    degrees, the boundary conforming Delaunay mesh property is
    guaranteed, hence the dual Voronoi diagram has no vertex lies
    outside the domain boundary - a desired property for finite volume
    partition.

-   Mesh coarsening (deleting mesh points) is now possible. Two ways are
    implemented for doing mesh coarsening: (1) The user can specify the
    points wanted to be removed by using the \"pointmarker\" list (i.e.,
    the last column in .node file), a \'0\' means \"remove this point\",
    otherwise \"keep it\"; or (2) The user can supply a mesh sizing
    function, let TetGen choose the point to remove, i.e., TetGen will
    remove a point if the mesh size at the point is too dense.

    The new command line option for mesh coarsening is \'-R\'. It can be
    used either with \'-p\' (to coarse a CDT) or \'-r\' (to coarse a
    previously generated mesh). You can also use \'-R\' and \'-q\'
    together. TetGen will first perform mesh coarsening then do mesh
    refinement, hence the process must terminate and the mesh quality is
    improved.

-   Implemented new mesh optimization and mesh smoothing functions which
    can be optionally performed to remove slivers and further improve
    mesh quality. High order edge flip operations (combination of
    several basic flips) (as suggested by Barry Joe \[Joe, 1995\]) are
    implemented. These operations help to remove the majority of
    slivers. The remaining slivers are then tried by mesh smoothing
    operations, which includes vertex moving and new vertex insertion.

-   Improved the mesh boundary preserving (the \'-Y\' option) function.
    Most of the relocated interior points can be completely suppressed,
    remaining points are smoothed.

-   New output of Voronoi diagrams. The Voronoi diagram is the geometric
    dual of the Delaunay triangulation. By using the \'-v\' option, the
    Voronoi diagram will be saved in files: .v.node, .v.edge, .v.face,
    and .v.cell.

-   Many bugs are fixed including the \'-o2\' option.

## Version 1.4.1 (July 28, 2006)

-   An adaptive mesh refinement algorithm has been implemented (for the
    \'-q\' option). This algorithm extends Shewchuk\'s basic Delaunay
    refinement algorithm in two ways: (1) no restriction on the input
    angle; (2) refines the mesh according to a sizing function which may
    be automatcially derived from input data or provided by user through
    a background mesh. A paper, \"On Refinement of Constrained Delaunay
    Tetrahedralizations\", describes the algorithm will appear in the
    proceeding of 15th international meshing roundtable, Birmingham AL,
    September 2006.
-   The \'-Y\' option (preserve the input boundary) has been improved.
    Generally, more than 95% additional points can be completely
    removed, the remaining points are relocated into the volume.
-   Many bugs are fixed.


## Version 1.4.0 (January 14, 2006)

-   Respect of the input boundary (the \'-Y\' switch). It is possible
    now to preserve the input surface mesh unchanged in the result
    tetrahedral mesh. A Steiner point removal algorithm based on
    Delaunay tetrahedralization kernel and constrained flips is
    implemented.
-   Shewchuk\'s Delaunay refinement algorithm has been improved. A new
    type of Steiner point called \"off-center\" (suggested in paper
    Alper Üngör, \"Quality Triangulation Made Smaller\", EWCG 2005) is
    used. This change reduces the number of refinement points (up to
    20%) and results in smaller meshes. Consequently, the mesh speed is
    improved too.
-   The constrained Delaunay tetrahedralization algorithm is improved. A
    simple symbolic perturbation is used to remove the spherical
    degeneracies of the point set which reduces the number of break
    points (thanks to Jonathan Shewchuk).
-   It is possible to let TetGen automatically assign the region
    attributes to tetrahedra. When the \'-AA\' switch is used, in the
    output mesh, every tetrahedron gets a non-zero attribute. Tetrahedra
    in the same region have the same attribute.
-   The \'-z\' switch has been activated. The ouput nodes can be indexed
    from zero.
-   Many bugs are fixed.
-   Many typos in the user\'s manual are corrected (thanks to David
    Day).

## Version 1.3.4 (June 17, 2005)

-   A new constrained Delaunay tetrahedralization algorithm has been
    completely implemented. Now the CDT construction is rather fast and
    stable. A paper, \"Meshing Piecewise Linear Complexes by Constrained
    Delaunay Tetrahedralizations\", describes the algorithm has
    submitted to the 14th international meshing roundtable held in
    Sandiego, September. Colleagues who have the interest to read it are
    very welcome to contact me.
-   In the -q switch. A new strategy for edge protecting has been used
    in the Delaunay mesh refinement which saves a quite number of
    additional points. It is a slighly modified version of our edge
    protecting algorithm (also presented in the above paper). The
    quality mesh step is more stable than old ones.
-   In the -q switch. A sliver removal step is added after the Delaunay
    refinement. It removes most of the survived slivers by flip
    operations and inserting points.
-   In the -q switch. More mesh refinement options are available.
    Besides the maximum volume constraint on tetrahedra, users now can
    set maximum area constraints on facets, maximum edge length
    constraint on segments.

