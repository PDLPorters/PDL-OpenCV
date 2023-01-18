(
['','destroyWindow','@brief Destroys the specified window.

The function destroyWindow destroys the window with the given name.

@param winname Name of the window to be destroyed.',0,'void',['String','winname','',['/C','/Ref']]],
['','imshow','@brief Displays an image in the specified window.

The function imshow displays an image in the specified window. If the window was created with the
cv::WINDOW_AUTOSIZE flag, the image is shown with its original size, however it is still limited by the screen resolution.
Otherwise, the image is scaled to fit the window. The function may scale the image, depending on its depth:

-   If the image is 8-bit unsigned, it is displayed as is.
-   If the image is 16-bit unsigned, the pixels are divided by 256. That is, the
    value range [0,255\\*256] is mapped to [0,255].
-   If the image is 32-bit or 64-bit floating-point, the pixel values are multiplied by 255. That is, the
    value range [0,1] is mapped to [0,255].
-   32-bit integer images are not processed anymore due to ambiguouty of required transform.
    Convert to 8-bit unsigned matrix using a custom preprocessing specific to image\'s context.

If window was created with OpenGL support, cv::imshow also support ogl::Buffer , ogl::Texture2D and
cuda::GpuMat as input.

If the window was not created before this function, it is assumed creating a window with cv::WINDOW_AUTOSIZE.

If you need to show an image that is bigger than the screen resolution, you will need to call namedWindow("", WINDOW_NORMAL) before the imshow.

@note This function should be followed by a call to cv::waitKey or cv::pollKey to perform GUI
housekeeping tasks that are necessary to actually show the given image and make the window respond
to mouse and keyboard events. Otherwise, it won\'t display the image and the window might lock up.
For example, **waitKey(0)** will display the window infinitely until any keypress (it is suitable
for image display). **waitKey(25)** will display a frame and wait approximately 25 ms for a key
press (suitable for displaying a video frame-by-frame). To remove the window, use cv::destroyWindow.

@note

[__Windows Backend Only__] Pressing Ctrl+C will copy the image to the clipboard.

[__Windows Backend Only__] Pressing Ctrl+S will show a dialog to save the image.

@param winname Name of the window.
@param mat Image to be shown.',0,'void',['String','winname','',['/C','/Ref']],['Mat','mat','',[]]],
['','namedWindow','@brief Creates a window.

The function namedWindow creates a window that can be used as a placeholder for images and
trackbars. Created windows are referred to by their names.

If a window with the same name already exists, the function does nothing.

You can call cv::destroyWindow or cv::destroyAllWindows to close the window and de-allocate any associated
memory usage. For a simple program, you do not really have to call these functions because all the
resources and windows of the application are closed automatically by the operating system upon exit.

@note

Qt backend supports additional flags:
 -   **WINDOW_NORMAL or WINDOW_AUTOSIZE:** WINDOW_NORMAL enables you to resize the
     window, whereas WINDOW_AUTOSIZE adjusts automatically the window size to fit the
     displayed image (see imshow ), and you cannot change the window size manually.
 -   **WINDOW_FREERATIO or WINDOW_KEEPRATIO:** WINDOW_FREERATIO adjusts the image
     with no respect to its ratio, whereas WINDOW_KEEPRATIO keeps the image ratio.
 -   **WINDOW_GUI_NORMAL or WINDOW_GUI_EXPANDED:** WINDOW_GUI_NORMAL is the old way to draw the window
     without statusbar and toolbar, whereas WINDOW_GUI_EXPANDED is a new enhanced GUI.
By default, flags == WINDOW_AUTOSIZE | WINDOW_KEEPRATIO | WINDOW_GUI_EXPANDED

@param winname Name of the window in the window caption that may be used as a window identifier.
@param flags Flags of the window. The supported flags are: (cv::WindowFlags)',0,'void',['String','winname','',['/C','/Ref']],['int','flags','WINDOW_AUTOSIZE',[]]],
['','selectROI','@brief Allows users to select a ROI on the given image.

The function creates a window and allows users to select a ROI using the mouse.
Controls: use `space` or `enter` to finish selection, use key `c` to cancel selection (function will return the zero cv::Rect).

@param windowName name of the window where selection process will be shown.
@param img image to select a ROI.
@param showCrosshair if true crosshair of selection rectangle will be shown.
@param fromCenter if true center of selection will match initial mouse position. In opposite case a corner of
selection rectangle will correspont to the initial mouse position.
@return selected ROI or empty rect if selection canceled.

@note The function sets it\'s own mouse callback for specified window using cv::setMouseCallback(windowName, ...).
After finish of work an empty callback will be set for the used window.',0,'Rect',['String','windowName','',['/C','/Ref']],['Mat','img','',[]],['bool','showCrosshair','true',[]],['bool','fromCenter','false',[]]],
['','waitKey','@brief Waits for a pressed key.

The function waitKey waits for a key event infinitely (when \\f$\\texttt{delay}\\leq 0\\f$ ) or for delay
milliseconds, when it is positive. Since the OS has a minimum time between switching threads, the
function will not wait exactly delay ms, it will wait at least delay ms, depending on what else is
running on your computer at that time. It returns the code of the pressed key or -1 if no key was
pressed before the specified time had elapsed. To check for a key press but not wait for it, use
#pollKey.

@note The functions #waitKey and #pollKey are the only methods in HighGUI that can fetch and handle
GUI events, so one of them needs to be called periodically for normal event processing unless
HighGUI is used within an environment that takes care of event processing.

@note The function only works if there is at least one HighGUI window created and the window is
active. If there are several HighGUI windows, any of them can be active.

@param delay Delay in milliseconds. 0 is the special value that means "forever".',0,'int',['int','delay','0',[]]],
);
