th=1.6;                 //Thickness of case walls
lth=0.2;                //Layer thickness
w=192.96+2.5*th;        //Width of case (x dim)
b=110.76+2.5*th;        //Breadth of case (y dim)
h=50;                   //Height of case (z dim)
r=7;                    //Radius of case corners
hd1=4;                  //Mount key hole diameter 1
hd2=9;                  //Mount key hole diameter 2
hdist=6;                //Mount key hole distance
hw=2*r+2;               //Mount plate width
seth=1;                 //Screen edge thickness 
smth=8;                 //Screen thickness at mounts
smdw=(w-126.2)/2;       //Screen mount hole offset in width direction
smdb=(b-65.65)/2;       //Screen mount hole offset in breadth direction
smhd=3.5;               //Screen mount hole diameter
smw=smdw+2*smhd;        //Screen mount width
smoff=[0,1,0];          //Screen mount offset
grille_width=th;        //Width of each ventilation grille
grille_dist=6*th;       //Distance between ventilation grilles
grille_count=12;        //Number of ventilation grilles
print_case = true;      //Should the case be printed or not
print_smplates = false; //Should the screen mount be printed or not

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
        rounded_box_sides(w,b,r,h,th);
        //Ventilation grille
        translate (v=[-0.5*grille_dist*(grille_count-1),th-b/2,0]) {
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
    }

    //Wall mount plates
    difference() {
        linear_extrude(height=th) {
            difference() {
                rounded_square(w,b,r);
                square(size=[w-2*hw,b-4*th],center=true);
            }
        }
        translate(v=[0,hdist/2,lth]) {
            linear_extrude(height=th) {
                for (cv = corner_vectors(w,b-hdist,r)) {
                    translate(v=cv) {
                        key_hole(hd1,hd2,hdist);
                    }
                }
            }
        }
    }

    //Screen support rim
    translate(v=[0,0,h-th/2-seth]) {
        rounded_box_sides(w-2*th,b-2*th,r-th,th/2,th);
    }
    translate(v=[0,0,h-th-seth]) {
        rounded_square_triag_ring(w-2*th,b-2*th,r-th,th/2,th);
    }

    //Screen mount support rims
    translate(v=[0,0,h-smth]) {
        difference() {
            union() {
                rounded_box_sides(w-2*th,b-2*th,r-th,smth-seth,th);
                translate(v=[0,0,-2*th-2*lth]) {
                    rounded_box_sides(w-2*th,b-2*th,r-th,th,th);
                }
                translate(v=[0,0,-3*th-2*lth]) {
                    rounded_square_triag_ring(w-2*th,b-2*th,r-th,th,th);
                }
            }
            cube(size=[w-2*smw,b,8*th],center=true);
        }
    }
}

if (print_smplates) {
    //Screen mount plates
    rotate(a=90) {
        difference() {
            linear_extrude(height=th, twist=0, center=false) {
                union() {
                    difference() {
                        rounded_square(2*smw+th-2*lth,b-2*th-2*lth,r-th);
                        square(size=[th,b],center=true);
                    }
                }
            }
            translate(v=[0,0,lth]+smoff) {
                for (cv = corner_vectors(2*smw+th-2*smdw,b-2*smdb,0))
                {
                    translate(v=cv) {
                        cylinder(d=smhd,h=th);
                    }
                }
            }
        }
    }
}