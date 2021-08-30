import bindbc.sdl;
import renderer.window;
import renderer.math;
//to be deleted at some point

				 
struct Engine
{
  
  Matrix4x4 projection = {0};
}

void main()
{
  SDLSupport ret = loadSDL();
  if(ret !=sdlSupport) {

    /*
      Handle error. For most use cases, it's reasonable to use the the error handling API in bindbc-loader to retrieve
      error messages for logging and then abort. If necessary, it's possible to determine the root cause via the return
      value:
    */

    if(ret == SDLSupport.noLibrary) {
      // The SDL shared library failed to load
    }
    else if(SDLSupport.badLibrary) {
      /*
	One or more symbols failed to load. The likely cause is that the shared library is for a lower version than bindbc-sdl was configured to load (via SDL_204, GLFW_2010 etc.)
      */
    }
  }
  SDL_Init(SDL_INIT_VIDEO);
  Window window = Window("lol");
  Engine engine;

  import core.stdc.math : tanf, cosf, sinf, floor;
  float fAspectRatio = window.aspectRatio();
  float fNear = 0.1f;
  float fFar = 1000.0f;
  float fPlane = 1000.0f;
  float fFov = 90.0f;
  float fFovRad = 1.0f / tanf(fFov * 0.5 / 180.0f * 3.14159f);

  
  Rect r1 = {50,50,10,10};
  Rect r2 = {100,50,10,10};
  Rect r3 = {200,200,10,10};

  engine.projection[0,0] = fAspectRatio * fFovRad;
  engine.projection[1,1] = fFovRad;
  engine.projection[2,2] = fFar / (fFar - fNear);
  engine.projection[3,2] = (-fFar * fNear) / (fFar - fNear);
  engine.projection[2,3] = 1.0f;

  Colour white = {255,255,255};
  Colour green = {255,0,255};

  Mesh!(float) mesh = {
    [
     //South
     Trianglef([[0.0f,0.0f,0.0f],[0.0f, 1.0f, 0.0f],[1.0f,1.0f,0.0f]]),
     Trianglef([[0.0f,0.0f,0.0f],[1.0f, 1.0f, 0.0f],[1.0f,0.0f,0.0f]]),

     //East
     Trianglef([[1.0f,0.0f,0.0f],[1.0f, 1.0f, 0.0f],[1.0f,1.0f,1.0f]]),
     Trianglef([[1.0f,0.0f,0.0f],[1.0f, 1.0f, 1.0f],[1.0f,0.0f,1.0f]]),

     //North
     Trianglef([[1.0f,0.0f,1.0f],[1.0f, 1.0f, 1.0f],[0.0f,1.0f,1.0f]]),
     Trianglef([[1.0f,0.0f,1.0f],[0.0f, 1.0f, 1.0f],[0.0f,0.0f,1.0f]]),
     
     //West
     Trianglef([[0.0f,0.0f,1.0f],[0.0f, 1.0f, 1.0f],[0.0f,1.0f,0.0f]]),
     Trianglef([[0.0f,0.0f,1.0f],[0.0f, 1.0f, 0.0f],[0.0f,0.0f,0.0f]]),

     //Top
     Trianglef([[0.0f,1.0f,0.0f],[0.0f, 1.0f, 1.0f],[1.0f,1.0f,1.0f]]),
     Trianglef([[0.0f,1.0f,0.0f],[1.0f, 1.0f, 1.0f],[1.0f,1.0f,0.0f]]),

     //Bottom
     Trianglef([[1.0f,0.0f,1.0f],[0.0f, 0.0f, 1.0f],[0.0f,0.0f,0.0f]]),
     Trianglef([[1.0f,0.0f,1.0f],[0.0f, 0.0f, 0.0f],[1.0f,0.0f,0.0f]])
     ]
  };
  
  mesh.triangles[0].colour = Colour.BLUE;
  mesh.triangles[1].colour = Colour.RED;
  mesh.triangles[2].colour = Colour.LIME;
  mesh.triangles[3].colour = Colour.WHITE;
  mesh.triangles[4].colour = Colour.YELLOW;
  mesh.triangles[5].colour = Colour.BLUE;
  mesh.triangles[6].colour = Colour.YELLOW;
  mesh.triangles[7].colour = Colour.RED;
  mesh.triangles[8].colour = Colour.BLUE;
  mesh.triangles[9].colour = Colour.RED;
  mesh.triangles[10].colour = Colour.LIME;
  mesh.triangles[11].colour = Colour.WHITE;
  
  

  Matrix4x4 matRotX = {0}, matRotZ = {0};
  float theta = 0;  
  
  bool exit = false;
  while (!exit) {
    auto start = SDL_GetPerformanceCounter();
    SDL_Event event;
    while (SDL_PollEvent(&event)) 
      {
	if (event.type == SDL_QUIT) exit = true;
	if (event.type == SDL_WINDOWEVENT)  
	  {
	    if (event.window.event == SDL_WINDOWEVENT_SIZE_CHANGED)
	      {
		window.surface = SDL_GetWindowSurface(window.window);
	      }
	  }
      }
    window.clear();

    theta += 0.01f;
    
    matRotZ[0,0] = cosf(theta);
    matRotZ[0,1] = sinf(theta);
    matRotZ[1,0] = -sinf(theta);
    matRotZ[1,1] = cosf(theta);
    matRotZ[2,2] = 1;
    matRotZ[3,3] = 1;

    matRotX[0,0] = 1;
    matRotX[1,1] = cosf(theta*0.5f);
    matRotX[1,2] = sinf(theta*0.5f);
    matRotX[2,1] = -sinf(theta*0.5f);
    matRotX[2,2] = cosf(theta*0.5f);
    matRotX[3,3] = 1;
    
    foreach(tri ; mesh.triangles) {

      Vec3f xrot = (matRotX * tri.points[0]);
      Vec3f yrot = (matRotX * tri.points[1]);
      Vec3f zrot = (matRotX * tri.points[2]);

      Trianglef triTranslate;
      triTranslate.points[0] = xrot;
      triTranslate.points[1] = yrot;
      triTranslate.points[2] = zrot;

      triTranslate.points[0][2] += 4.0f;
      triTranslate.points[1][2] += 4.0f;
      triTranslate.points[2][2] += 4.0f;
      
      Vec3f a = engine.projection * triTranslate.points[0];
      Vec3f b = engine.projection * triTranslate.points[1];
      Vec3f c = engine.projection * triTranslate.points[2];

      a[0] += 1; a[1] += 1;
      b[0] += 1; b[1] += 1;
      c[0] += 1; c[1] += 1;

      a[0] *= 0.5f * window.width();
      a[1] *= 0.5f * window.height();
      
      b[0] *= 0.5f * window.width();
      b[1] *= 0.5f * window.height();

      c[0] *= 0.5f * window.width();
      c[1] *= 0.5f * window.height();
      import std.stdio;
      if (tri.colour == Colour.WHITE) {
	writeln(a.toPoint.toString(), " ", b.toPoint().toString(), " ", c.toPoint.toString());
      }
      window.drawTriangle(a.toPoint(), b.toPoint(), c.toPoint(), tri.colour);
    }

    SDL_UpdateWindowSurface(window.window);

    auto end = SDL_GetPerformanceCounter();

    float elapsedMS = (end - start) / cast(float)SDL_GetPerformanceFrequency() * 1000.0f;

    SDL_Delay(cast(uint)floor(16.666f - elapsedMS));
  }
}
