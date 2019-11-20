// Hello, sinewaves!
// by Chris Gahan
//
// To compile, run:
//     gcc hello-sinewaves.c -o hello-sinewaves -lm -lGL -lglut

#include <GL/glut.h>
#include <math.h>
#include <stdio.h>

#ifndef M_PI
  #define M_PI 3.14159265358979323846 /* pi! */
#endif

#define WIDTH 640.0
#define HEIGHT 480.0
#define DELAY 10

GLfloat time = 0.0;
GLfloat timestep = 0.5;


void wave(GLfloat amplitude, GLfloat width, GLfloat offset, GLfloat funk) {

    GLfloat x, y, z = 1.0;
    GLfloat f = (M_PI*2)/width;
    GLfloat a = (HEIGHT/2)*amplitude;
    GLfloat o = (M_PI*2) * offset/WIDTH;

    glBegin(GL_LINE_STRIP);
    // Left segment (flipped horizontally and vertically)
    for (x = WIDTH/2; x >= 0.0; x -= 2.0) {
        y = sin(x*f+o)*a*sin(x*M_PI/funk) + HEIGHT/2;
        glVertex3f(WIDTH/2-x, HEIGHT-y, z);
    }
    // Right segment (shifted over by WIDTH/2)
    for (x = 0.0; x <= WIDTH/2; x += 2.0) {
        y = sin(x*f+o)*a*sin(x*M_PI/funk) + HEIGHT/2;
        glVertex3f(x+WIDTH/2, y, z);
    }
    glEnd();

}


void RenderScene(void)
{
    GLfloat i;

    glClear(GL_COLOR_BUFFER_BIT);

    for (i = 0.0; i < 1.0 ; i += 0.1) {
        glColor3f(i*0.8+0.2, 0.0, 0.5);
        //     amplitude,  width, offset,           funk!
        wave((1.0-i)/1.0, 50.0*i, time*5, (i*50000.0)/(200-time));
    }

    glFlush();
    glutSwapBuffers();
}


// Setup the Rendering Context
void SetupRC(void) {
    glClearColor(0.0f, 0.0f, 0.0f, 1.0f);
    // glViewport(0, 0, 640, 200);
}


// Called by GLUT library when the window has chanaged size
void ChangeSize(GLsizei w, GLsizei h)
{
    // Prevent a divide by zero
    if(h == 0) h = 1;

    // Set Viewport to window dimensions
    glViewport(0, 0, w, h);

    // Reset coordinate system
    glMatrixMode(GL_PROJECTION);
    glLoadIdentity();


    // Establish clipping volume (left, right, bottom, top, near, far)
    glOrtho (0.0, WIDTH, HEIGHT, 0.0, 1.0, -1.0);

    glMatrixMode(GL_MODELVIEW);
    glLoadIdentity();
}


void TimerFunction(int value) {

    time += timestep;
    glutPostRedisplay();
    glutTimerFunc(DELAY, TimerFunction, 1);

}


int main(int argc, char* argv)
{
    printf("Version: %s\nExtensions: %s\n", glGetString(GL_VERSION), glGetString(GL_EXTENSIONS));
    printf("Delay: %d\n", DELAY);

    glutInit(&argc, &argv);

    glutInitWindowSize(1280, 400);
    glutInitDisplayMode(GLUT_DOUBLE | GLUT_RGB);
    glutCreateWindow("Hello Sine-Waves!");

    glutDisplayFunc(RenderScene);
    glutReshapeFunc(ChangeSize);
    glutTimerFunc(DELAY, TimerFunction, 1);

    SetupRC();

    glutMainLoop();
}
