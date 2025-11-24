#include <verilated.h>          // defines common routines
#include <GL/glut.h>
#include <thread>
#include <iostream>

#include "Vbrus16_top.h"           // from Verilating "display.v"

using namespace std;

Vbrus16_top* display;              // instantiation of the model

uint64_t main_time = 0;         // current simulation time
double sc_time_stamp() {        // called by $time in Verilog
    return main_time;
}

// to wait for the graphics thread to complete initialization
bool gl_setup_complete = false;

// 640X480 VGA sync parameters
const int LEFT_PORCH		= 	48;
const int ACTIVE_WIDTH		= 	640;
const int RIGHT_PORCH		= 	16;
const int HORIZONTAL_SYNC	=	96;
const int TOTAL_WIDTH		=	800;

const int TOP_PORCH			= 	33;
const int ACTIVE_HEIGHT		= 	480;
const int BOTTOM_PORCH		= 	10;
const int VERTICAL_SYNC		=	2;
const int TOTAL_HEIGHT		=	525;

// pixels are buffered here
uint8_t graphics_buffer[ACTIVE_WIDTH][ACTIVE_HEIGHT][3] = {};

// calculating each pixel's size in accordance to OpenGL system
// each axis in OpenGL is in the range [-1:1]
float pixel_w = 2.0f / ACTIVE_WIDTH;
float pixel_h = 2.0f / ACTIVE_HEIGHT;

// gets called periodically to update screen
void render(void) {
    glClear(GL_COLOR_BUFFER_BIT);
    
    // convert pixels into OpenGL rectangles
    for(int i = 0; i < ACTIVE_WIDTH; i++){
        for(int j = 0; j < ACTIVE_HEIGHT; j++){
            glColor3ub(graphics_buffer[i][j][0], graphics_buffer[i][j][1], graphics_buffer[i][j][2]);
            glRectf(i*pixel_w-1, -j*pixel_h+1, (i+1)*pixel_w-1, -(j+1)*pixel_h+1);
        }
    }
    
    glFlush();
}

// timer to periodically update the screen
void glutTimer(int t) {
    glutPostRedisplay(); // re-renders the screen
    glutTimerFunc(t, glutTimer, t);
}

// handle up/down/left/right arrow keys
int keys[4] = {0, 0, 0, 0};
void Special_input(int key, int x, int y) {
    switch(key) {
        case GLUT_KEY_UP:
            keys[0] = 1;
            break;
        case GLUT_KEY_DOWN:
            keys[1] = 1;
            break;
        case GLUT_KEY_LEFT:
            keys[2] = 1;
            break;
        case GLUT_KEY_RIGHT:
            keys[3] = 1;
            break;
    }
}

// initiate and handle graphics
void graphics_loop(int argc, char** argv) {
    glutInit(&argc, argv);
    glutInitDisplayMode(GLUT_SINGLE);
    glutInitWindowSize(ACTIVE_WIDTH, ACTIVE_HEIGHT);
    glutInitWindowPosition(100, 100);
    glutCreateWindow("Brus 16 Verilator simulation");
    glutDisplayFunc(render);
    glutSpecialFunc(Special_input);
    
    gl_setup_complete = true;
    
    // re-render every 16ms, around 60Hz
    glutTimerFunc(16, glutTimer, 16);
    glutMainLoop();
}

// tracking VGA signals
int coord_x = 0;
int coord_y = 0;
bool pre_h_sync = 0;
bool pre_v_sync = 0;

// set Verilog module inputs based on arrow key inputs
// void apply_input() {
//     uint16_t buttons = 0;
//     buttons |= keys[0] << 0; // up
//     buttons |= keys[1] << 1; // down
//     buttons |= keys[2] << 2; // left
//     buttons |= keys[3] << 3; // right
//     display->buttons_in = buttons;
// }

// void discard_input() {
//     display->buttons_in = (uint16_t) 0;
//     for (int i = 0; i < 4; i++)
//     {
//         keys[i] = 0;
//     }
// }

void from_rgb565(uint16_t color, uint8_t *r, uint8_t *g, uint8_t *b) {
    uint8_t r5 = (color >> 11) & 0x1f;
    uint8_t g6 = (color >> 5) & 0x3f;
    uint8_t b5 = color & 0x1f;
    *r = (r5 << 3) | (r5 >> 2);
    *g = (g6 << 2) | (g6 >> 4);
    *b = (b5 << 3) | (b5 >> 2);
}

// read VGA outputs and update graphics buffer
void sample_pixel() {
    // apply_input();
    
    coord_x = (coord_x + 1) % TOTAL_WIDTH;

    if(!display->hsync_out && pre_h_sync){ // on negative edge of h_sync
        // re-sync horizontal counter
        coord_x = RIGHT_PORCH + ACTIVE_WIDTH + HORIZONTAL_SYNC;
        coord_y = (coord_y + 1) % TOTAL_HEIGHT;
    }

    if(!display->vsync_out && pre_v_sync){ // on negative edge of v_sync
        // re-sync vertical counter
        coord_y = TOP_PORCH + ACTIVE_HEIGHT + VERTICAL_SYNC;
        // discard_input(); // inputs are pulsed once each new frame
    }

    if(coord_x < ACTIVE_WIDTH && coord_y < ACTIVE_HEIGHT){
        uint8_t r, g, b;
        from_rgb565(display->rgb_out, &r, &g, &b);
        graphics_buffer[coord_x][coord_y][0] = r;
        graphics_buffer[coord_x][coord_y][1] = g;
        graphics_buffer[coord_x][coord_y][2] = b;
    }

    pre_h_sync = display->hsync_out;
    pre_v_sync = display->vsync_out;
}

// simulate for a single clock
void tick() {
    // update simulation time
    main_time++;

    // rising edge
    display->clk = 1;
    display->eval();

    // falling edge
    display->clk = 0;
    display->eval();
}

// globally reset the model
// void reset() {
//     display->reset = 1;
//     display->clk = 0;
//     display->eval();
//     tick();
//     display->reset = 0;
// }

int main(int argc, char** argv) {
    // create a new thread for graphics handling
    thread thread(graphics_loop, argc, argv);
    // wait for graphics initialization to complete
    while(!gl_setup_complete);

    Verilated::commandArgs(argc, argv);   // remember args

    // create the model
    display = new Vbrus16_top;

    // reset the model
    // reset();

    // cycle accurate simulation loop
    while (!Verilated::gotFinish()) {
        tick();
        sample_pixel();
    }

    display->final();
    delete display;
}

