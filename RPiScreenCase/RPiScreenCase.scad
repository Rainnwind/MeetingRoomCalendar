th=1;                   //Thickness of case walls
w=192.96+3*th;          //Width of case (x dim)
b=110.76+3*th;          //Breadth of case (y dim)
h=50;                   //Height of case (z dim)
r=7;                    //Radius of case corners
hd1=4;                  //Mount key hole diameter 1
hd2=9;                  //Mount key hole diameter 2
hdist=6;                //Mount key hole distance
hw=2*r+2;               //Mount plate width
seth=1;                 //Screen edge thickness 
smth=6;                 //Screen thickness at mounts
smdw=(w-126.2)/2;       //Screen mount hole offset in width direction
smdb=(b-65.65)/2;       //Screen mount hole offset in breadth direction
smhd=3.5;               //Screen mount hole diameter
smw=smdw+2*smhd;        //Screen mount width
smoff=[0,1];            //Screen mount offset

$fn=50;
//returns a vector of the center of the circle at each corner 
//of a rounded square in the x-y plane
function corner_vectors(width, breadth, radius = 0) = 
    [
        [radius,radius,0],
        [width-radius,radius,0],
        [radius,breadth-radius,0],
        [width-radius,breadth-radius,0]];
    

module rounded_square(width,breadth,radius) {
    union() {
        translate(v=[radius,0,0]) {
            square(size=[width-2*radius,breadth],center=false);
        }
        translate(v=[0,radius,0]) {
            square(size=[width,breadth-2*radius],center=false);
        }
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
            offset(r=-1*thickness) {
                rounded_square(width,breadth,radius);
            }
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

rounded_box_sides(w,b,r,h,th);


//Wall mount plates
linear_extrude(height=th) {
    difference() {
        rounded_square(w,b,r);
        translate(v=[hw,0,0]) {
            square(size=[w-2*hw,b]);
        }
        translate(v=[0,hdist,0]) {
            for (cv = corner_vectors(w,b-hdist,r)) {
                translate(v=cv) {
                    key_hole(hd1,hd2,hdist);
                }
            }
        }
    }
}

//Screen support rim
translate(v=[0,0,h-th-seth]) {
    rounded_box_sides(w,b,r,th,4*th);
}

//Screen mounts
translate(v=[0,0,h-th-smth]) {
    linear_extrude(height=th, twist=0, center=false) {
        union() {
            difference() {
                rounded_square(w-2*th,b-2*th,r-th);
                translate(v=[smw,0,0]) {
                    square(size=[w-2*smw,b]);
                }
                translate(v=[smdw,smdb,0]+smoff) {
                    for (cv = corner_vectors(w-2*smdw,b-2*smdb,0))
                    {
                        translate(v=cv) {
                            circle(d=smhd);
                        }
                    }
                }
            }
        }
    }    
}
