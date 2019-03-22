include <RPiDims.scad>
use <RPiModules.scad>

rpi_wall_mount(true);

for (i=[-1,1]) {
    translate([i*(width-mount_plate_width)/2,0,thickness]) {
        //Cable hole boxes (left/right)
        cube(size=[mount_plate_width,cable_hole_width+2*thickness,thickness],center=true);
    }
    translate([0,i*(breadth-4*thickness)/2,thickness]) {
        //Cable hole boxes (top/bottom)
        cube(size=[cable_hole_width+2*thickness,4*thickness,thickness],center=true);
    }
}
