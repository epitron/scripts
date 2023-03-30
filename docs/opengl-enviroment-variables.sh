# Reference:
#   https://download.nvidia.com/XFree86/Linux-x86_64/465.31/README/openglenvvariables.html

# 0 No anisotropic filtering
# 1 2x anisotropic filtering
# 2 4x anisotropic filtering
# 3 8x anisotropic filtering
# 4 16x anisotropic filtering
export __GL_LOG_MAX_ANISO=4

export __GL_SYNC_TO_VBLANK=1


# $ nvidia-settings --query=fsaa --verbose

# Attribute 'FSAA' (grog:0.0): 0.
#   Valid values for 'FSAA' are: 0, 1, 5, 9, 10 and 11.
#   'FSAA' can use the following target types: X Screen.

#   Note to assign 'FSAA' on the commandline, you may also need to assign
#   'FSAAAppControlled' and 'FSAAAppEnhanced' to 0.

#   Valid 'FSAA' Values
#     value - description
#       0   -   Off
#       1   -   2x (2xMS)
#       5   -   4x (4xMS)
#       9   -   8x (4xSS, 2xMS)
#      10   -   8x (8xMS)
#      11   -   16x (4xSS, 4xMS)

export __GL_FSAA_MODE=11

# shows info like api, framerate, vsync, etc.
#export  __GL_SHOW_GRAPHICS_OSD=1


# The __GL_SHARPEN_ENABLE environment variable can be used to enable image sharpening for OpenGL and Vulkan applications. Setting __GL_SHARPEN_ENABLE=1 enables image sharpening, while setting __GL_SHARPEN_ENABLE=0 (default) disables image sharpening. The amount of sharpening can be controlled by setting the __GL_SHARPEN_VALUE environment variable to a value between 0 and 100, with 0 being no sharpening, 100 being maximum sharpening, and 50 being the default. The amount of denoising done on the sharpened image can be controlled with the __GL_SHARPEN_IGNORE_FILM_GRAIN environment variable, with 0 being no denoising, 100 being maximum denoising, and 17 being the default.

