//Version 8
th=1.6;                 //Thickness of case walls
lth=0.2;                //Layer thickness
w=192.96+2.5*th;        //Width of case (x dim)
b=110.76+2.5*th;        //Breadth of case (y dim)
h=55;                   //Height of case (z dim)
r=7;                    //Radius of screen corners
hd1=4;                  //Mount key hole diameter 1
hd2=9;                  //Mount key hole diameter 2
hw=2*(r+th);            //Mount plate width
hdist=6;                //Mount key hole distance
seth=0.8;               //Screen edge thickness 
smth=8.5;               //Screen thickness at mounts
smhd=3.5;               //Screen mount hole diameter
smw=3*smhd;             //Screen mount plate width
smdx=125.46;            //Distance between screen mount holes in x direction
smdy=65.8;              //Distance between screen mount holes in y direction
smoffx=1.05;            //Screen mount holes offset from center in x direction
smoffy=0.5;             //Screen mount holes offset from center in y direction
grille_width=1.5*th;    //Width of each ventilation grille
grille_dist=6*th;       //Distance between ventilation grilles
grille_count=12;        //Number of ventilation grilles
print_case = true;      //Should the case be printed or not
print_smplates = true;  //Should the screen mount be printed or not
cable_hole_height = 10; //
cable_hole_width=12;    //

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

if (print_case) {
    //Main box
    difference() {
        //Rounded sides
        union() {
            rounded_box_sides(w,b,r+th,h,th);
            for (i=[-1,1]) {
                translate([i*(w-hw)/2,0,cable_hole_height/2+th]) {
                    //Cable hole boxes (left/right)
                    cube(size=[hw,cable_hole_width+2*th,cable_hole_height+2*th],center=true);
                    for (j=[-1,1]) {
                        translate([0,j*(b-1.5*hw)/2,-cable_hole_height/2-th]) {
                            rounded_box_sides(hw,1.5*hw,r+th,h/2,th);
                        }
                    }
                }
                translate([0,i*(b-4*th)/2,cable_hole_height/2+th]) {
                    //Cable hole boxes (top/bottom)
                    cube(size=[cable_hole_width+2*th,4*th,cable_hole_height+2*th],center=true);
                }
            }
        }
        //Ventilation grille
        translate (v=[-0.5*grille_dist*(grille_count-1),th-b/2,0.15*h]) {
            rotate(a = 90,v=[1,0,0]) {
                for (i = [0:grille_count-1]) {
                    translate (v=[i*grille_dist,4*grille_width,-b]) {
                        //Ventilation grille
                        linear_extrude(height=b+2*th, twist=0, center=false) {
                            union() {
                                circle(d=grille_width);
                                translate(v=[-0.5*grille_width,0,0]) {
                                    square(size=[grille_width,0.4*h]);
                                }
                                translate(v=[0,0.4*h,0]) {
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
            translate([i*(w-hw)/2,0,cable_hole_height/2+th]) {
                cube(size=[hw-th,cable_hole_width,cable_hole_height], center=true);
            }
            translate([0,i*(b-4*th)/2,cable_hole_height/2+th]) {
                //Cable hole boxes (top/bottom)
                cube(size=[cable_hole_width,3*th,cable_hole_height],center=true);
            }
        }
    }

    //Wall mount plates
    difference() {
        linear_extrude(height=th) {
            difference() {
                rounded_square(w,b,r+th);
                square(size=[w-2*hw,b-8*th],center=true);
            }
        }
        translate(v=[0,hdist/2,0]) {
            linear_extrude(height=th) {
                for (cv = corner_vectors(w,b-hdist,r+th)) {
                    translate(v=cv) {
                        key_hole(hd1,hd2,hdist);
                    }
                }
            }
        }
    }

    //Screen mount support rims
    translate(v=[0,0,h-smth]) {
        rounded_box_sides(w-2*th,b-2*th,r,smth-seth,2*th);
        translate(v=[0,0,-2*th]) {
            difference() {
                rounded_square_triag_ring(w-2*th,b-2*th,r,2*th,2*th);
                for (i=[-1,1]) {
                    translate(v=[i*smdx*0.5+smoffx,0,th]) {
                        cube([7*smhd,b-2*th,2*th], true);
                    }
                }
            }
        }
    }
    
}

if (print_smplates) {
    //Screen mount plates
    rotate(90) {
        for (i=[-1,1]) {
            translate([i*4*smhd,0,th]) {
                difference() {
                    cube([5*smhd,b-2*th,2*th], true);
                    for (i=[-1,1]) {
                        translate([0,i*smdy/2+smoffy,0]) {
                            for (j=[-1,1]) {
                                translate([0,j*smhd/2,0]) {
                                    cylinder(d=smhd,h=2*th,center=true);
                                }
                            }
                            cube([smhd,smhd,2*th],true);
                        }
                    }
                }
            }
        }
    }
}