//Version 8
include <RPiDims.scad>;

$fn=25;
//returns a vector of the center of the circle at each corner 
//of a rounded square in the x-y plane
function corner_vectors(width, breadth, radius = 0) = 
    [
        [radius-width/2,radius-breadth/2,0],
        [width/2-radius,radius-breadth/2,0],
        [radius-width/2,breadth/2-radius,0],
        [width/2-radius,breadth/2-radius,0]];

module rounded_square(width,breadth,radius) {
    union() {
        square(size=[width-2*radius,breadth],center=true);
        square(size=[width,breadth-2*radius],center=true);
        
        for(cv = corner_vectors(width,breadth,radius)) {
            translate(v=cv) {
                circle(r=radius);
            }
        }
    }
}

module rounded_box_sides(width,breadth,radius,height,thickness) {
    linear_extrude(height=height) {
        difference() {
            rounded_square(width,breadth,radius);
            rounded_square(width-2*thickness,breadth-2*thickness,radius-thickness);
        }
    }
}

module key_hole(d1,d2,dist) {
    circle(d=d1);
    translate(v=[0,-1*dist,0]) {
        circle(d=d2);
    }
    translate(v=[0,-0.5*dist,0]) {
        square(size=[d1,dist], center=true);
    }
}

module rounded_square_triag_ring(width,breadth,radius,height,thickness) {
    difference() {
        rounded_box_sides(width,breadth,radius,height,thickness);
        linear_extrude(height=height,scale=[1-2*thickness/width,1-2*thickness/breadth]) {
            rounded_square(width,breadth,radius);
        }
    }
}

module rpi_wall_mount(remove_center_square = true, print_holes = true) {

    //Wall mount plates
    difference() {
        linear_extrude(height=thickness) {
            difference() {
                rounded_square(width,breadth,corner_radius+thickness);
                if (remove_center_square) {
                    square(size=[width-2*mount_plate_width,breadth-8*thickness],center=true);
                }
            }
        }
        if (print_holes) {
            translate(v=[0,hdist/2,0]) {
                linear_extrude(height=thickness) {
                    for (cv = corner_vectors(width,breadth-hdist,corner_radius+thickness)) {
                        translate(v=cv) {
                            key_hole(hd1,hd2,hdist);
                        }
                    }
                }
            }
        }
    }

}

module rpi_case(print_holes = true)
{
    difference() {
        //Rounded sides
        union() {
            rounded_box_sides(width,breadth,corner_radius+thickness,height,thickness);
            for (i=[-1,1]) {
                translate([i*(width-mount_plate_width)/2,0,cable_hole_height/2+thickness]) {
                    //Cable hole boxes (left/right)
                    cube(size=[mount_plate_width,cable_hole_width+2*thickness,cable_hole_height+2*thickness],center=true);
                    for (j=[-1,1]) {
                        translate([0,j*(breadth-1.5*mount_plate_width)/2,-cable_hole_height/2-thickness]) {
                            rounded_box_sides(mount_plate_width,1.5*mount_plate_width,corner_radius+thickness,cable_hole_height+2*thickness,thickness);
                        }
                    }
                }
                translate([0,i*(breadth-4*thickness)/2,cable_hole_height/2+thickness]) {
                    //Cable hole boxes (top/bottom)
                    cube(size=[cable_hole_width+2*thickness,4*thickness,cable_hole_height+2*thickness],center=true);
                }
            }
        }
        //Ventilation grille
        translate (v=[-0.5*grille_dist*(grille_count-1),thickness-breadth/2,0.15*height]) {
            rotate(a = 90,v=[1,0,0]) {
                for (i = [0:grille_count-1]) {
                    translate (v=[i*grille_dist,4*grille_width,-breadth]) {
                        //Ventilation grille
                        linear_extrude(height=breadth+2*thickness, twist=0, center=false) {
                            union() {
                                circle(d=grille_width);
                                translate(v=[-0.5*grille_width,0,0]) {
                                    square(size=[grille_width,0.4*height]);
                                }
                                translate(v=[0,0.4*height,0]) {
                                    circle(d=grille_width);
                                }
                            }
                        }
                    }
                }
            }
        }
        //Cable holes
        for (i=[-1,1]) {
            translate([i*(width-mount_plate_width)/2,0,cable_hole_height/2+thickness]) {
                cube(size=[mount_plate_width-thickness,cable_hole_width,cable_hole_height], center=true);
            }
            translate([0,i*(breadth-4*thickness)/2,cable_hole_height/2+thickness]) {
                //Cable hole boxes (top/bottom)
                cube(size=[cable_hole_width,3*thickness,cable_hole_height],center=true);
            }
        }
    }

    rpi_wall_mount();

    //Screen mount support rims
    translate(v=[0,0,height-screen_thickness_at_mounts]) {
        rounded_box_sides(width-2*thickness,breadth-2*thickness,corner_radius,screen_thickness_at_mounts-screen_edge_thickness,2*thickness);
        translate(v=[0,0,-2*thickness]) {
            difference() {
                rounded_square_triag_ring(width-2*thickness,breadth-2*thickness,corner_radius,2*thickness,2*thickness);
                for (i=[-1,1]) {
                    translate(v=[i*screen_mount_dist_x*0.5+screen_mount_offset_x,0,thickness]) {
                        cube([7*screen_mount_hole_diameter,breadth-2*thickness,2*thickness], true);
                    }
                }
            }
        }
    }
}

module rpi_screen_mount_plates() {
    //Screen mount plates
    rotate(90) {
        for (i=[-1,1]) {
            translate([i*4*screen_mount_hole_diameter,0,thickness]) {
                difference() {
                    cube([5*screen_mount_hole_diameter,breadth-2*thickness,2*thickness], true);
                    for (i=[-1,1]) {
                        translate([0,i*screen_mount_dist_y/2+screen_mount_offset_y,0]) {
                            for (j=[-1,1]) {
                                translate([0,j*screen_mount_hole_diameter/2,0]) {
                                    cylinder(d=screen_mount_hole_diameter,h=2*thickness,center=true);
                                }
                            }
                            cube([screen_mount_hole_diameter,screen_mount_hole_diameter,2*thickness],true);
                        }
                    }
                }
            }
        }
    }
}

module rpt_mount_plate() {
    linear_extrude(height=thickness) {
        difference() {
            square(size=[width-2*mount_plate_width-2*lth,breadth-8*thickness-2*lth],center=true);
            for (i=[-1,1]) {
                translate(v=[i*75/2,breadth/2-40-lth]) {
                    key_hole(hd1,hd2,hdist);
                }
            }

        }
    }
    for (i=[-1,1]) {
        translate(v=[i*width/4,(breadth-8*thickness)/2-thickness-lth,thickness]) {
            intersection() {
                linear_extrude(height=thickness, scale=2) {
                    square([width/4,2*thickness], center=true);
                }
                translate([0,thickness,0]) {
                    linear_extrude(height=thickness) {
                        square([width/4,2*thickness], center=true);
                    }
                }
            }
            translate([0,thickness,thickness]) {
                linear_extrude(height=thickness) {
                    square([width/4,2*thickness], center=true);
                }
            }
                linear_extrude(height=2*thickness) {
                    square([width/4,2*thickness], center=true);
                }

        }
    }
}
