module renderer.window;

import bindbc.sdl;
import renderer.math;

import std.stdio;

struct Colour
{
  ubyte r, g, b;

  uint toPixel(const SDL_PixelFormat * format) {
    return SDL_MapRGBA(format, r, g, b, 0xFF);
  }

  const string toString() {
    import std.format : format;
    return format("[r: %d, g: %d, b: %d]\n", r, g, b);
  }

  static Colour BLUE    = {0,0,255};
  static Colour RED     = {255,0,0};
  static Colour LIME    = {0,255,0};
  static Colour BLACK   = {0,0,0};
  static Colour WHITE   = {255,255,255};
  static Colour YELLOW  = {255,255,0};
  static Colour CYAN    = {0,255,255};
  static Colour MAGENTA = {255,0,255};
  static Colour SILVER  = {192,192,192};
  static Colour GRAY    = {128,128,128};
  static Colour MAROON  = {128,0,0};
}



struct Rect
{
  uint x, y, w, h;
}

struct Window
{
  @disable this(this);
  SDL_Window * window = null;
  SDL_Surface * surface = null;

  auto getSurfaceFormat() const {
    return surface.format.format;
  }
  
  auto width() const {
    return surface.w;
  }
  
  auto height() const {
    return surface.h;
  }
  
  float aspectRatio() const {
    return cast(float) surface.w / surface.h;
  }

  auto bytesPerPixel() const {
    return surface.format.BytesPerPixel;
  }

  this(string windowName) {
    assert(window == null && surface == null);
    window = SDL_CreateWindow(
		 cast(char*) windowName,
		 SDL_WINDOWPOS_CENTERED, SDL_WINDOWPOS_CENTERED,
		 640, 480,
		 SDL_WINDOW_RESIZABLE);
    surface = SDL_GetWindowSurface(window);
  }

  void setWindowColour(Colour colour) {
    import core.stdc.string : memset, memcpy;    
    SDL_LockSurface(surface);
    
    const uint rgbaColour = colour.toPixel(surface.format);
    uint * pixels = cast(uint*) surface.pixels;
    const uint pixelsCount = surface.w * surface.h;
    pixels[0 .. pixelsCount] = rgbaColour;
    
    SDL_UnlockSurface(surface);
  }
  
  void clear() {
    import core.stdc.string : memset;
    SDL_LockSurface(surface);
    memset(surface.pixels, 0x00, surface.h * surface.pitch);
    SDL_UnlockSurface(surface);
  }

  void writePixel(Point point, Colour colour){
    assert(point.x >= 0 && point.x < surface.w &&
	   point.y >= 0 && point.y < surface.h);
    SDL_LockSurface(surface);
    uint * pixels = cast(uint*)surface.pixels;
    pixels[point.x + point.y * surface.w] =
      SDL_MapRGBA(surface.format, colour.r, colour.g, colour.b, 255);
    SDL_UnlockSurface(surface);
  }
  void drawLine(uint x1, uint y1, uint x2, uint y2, Colour colour) {
    drawLine(Point(x1,y1),Point(x2,y2),colour);
  }
  void drawLine(Point a, Point b, Colour colour) {
    
    void swap(ref int a, ref int b)
    {
      int temp = a;
      a = b;
      b = temp;
    }
    
    SDL_LockSurface(surface);
    uint * pixels = cast(uint*)surface.pixels;

    if (a.x < 0) a.x = 0;
    if (a.x >= surface.w) a.x = surface.w - 1;

    if (b.x < 0) b.x = 0;
    if (b.x >= surface.w) b.x = surface.w - 1;

    if (a.y < 0) a.y = 0;
    if (a.y >= surface.h) a.y = surface.h - 1;

    if (b.y < 0) b.y = 0;
    if (b.y >= surface.h) b.y = surface.h - 1;
    
    int dx = a.x - b.x;
    int dy = a.y - b.y;
    
    
    const c = colour.toPixel(surface.format);
    if (dx == 0) 
      {
	if (a.y > b.y) {
	  swap(a.y, b.y);
	}
	int pixelBufferIndex = (a.x | b.x) + a.y * surface.w;
	
	int length = b.y - a.y;
	
	for(int i = 0; i < length; ++i)
	  {
	    pixels[pixelBufferIndex] = c;

	    pixelBufferIndex += surface.w;
	  }
      }
    else if (dy == 0){
      int y = a.y | b.y;
      
      if (a.x > b.x) {
	  swap(a.x, b.x);
      }
      const int difference = b.x - a.x;
      const size_t start = a.x + y * surface.w;
      const size_t end = start + difference;
      pixels[start .. end] = c;
    }
    else 
      {
        //if (a.x > b.x) swap (a.x, b.x);
	//if (a.y > b.y) swap (a.y, b.y);
	dx = b.x - a.x;
	dy = b.y - a.y;

	int x = a.x;
	int y = a.y;

	int p = 2 * dy - dx;
        
	while (x < b.x) {
	  pixels[x + y * surface.w] = c;
	  
	  if (p > 0) {
	    p -= 2 * dx;
	    ++y;
	  }else{
	    p = p + 2 * dy;
	    x++;
	  }
	}
      }  
    SDL_UnlockSurface(surface);
  }
  
  void drawRect(Rect rect, Colour colour) {
    SDL_LockSurface(surface);
    uint * pixels = cast(uint*)surface.pixels;

    if (rect.x < 0)
      rect.x = 0;
    if (rect.x > surface.w) return;
    
    if (rect.y < 0)
      rect.y = 0;
    if (rect.y > surface.h) return;
    
    if ((rect.x + rect.w) > surface.w)
      rect.w = surface.w - rect.x;

    if ((rect.y + rect.h) > surface.h)
      rect.h = surface.h - rect.y;

    const uint rgbaColour = colour.toPixel(surface.format);
    uint index = rect.x + rect.y * surface.w;
    for(uint row = 0; row < rect.h; ++row) {
      index += surface.w;
      pixels[index .. index + rect.w] = rgbaColour;
    }
    
    SDL_UnlockSurface(surface);
  }
  void drawTriangle(Point p1, Point p2, Point p3, Colour colour)
  {
    drawLine(p1, p2, colour);
    drawLine(p2, p3, colour);
    drawLine(p1, p3, colour);
  }
}
