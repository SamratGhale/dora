package main

import im "shared:odin-imgui"
import im_gl "shared:odin-imgui/imgui_impl_opengl3"
import "core:path/filepath"
import im_sdl "shared:odin-imgui/imgui_impl_sdl2"

import gl "vendor:OpenGL"
import sdl "vendor:sdl2"

import "core:os"

import "core:fmt"
import "core:strings"

import win32 "core:sys/windows"

/**
	Start from C:
	List the directories
*/


to_cstr :: strings.unsafe_string_to_cstring

App :: struct {
	curr_dir: cstring,
	childs:   [dynamic]os.File_Info,
}

app: App

refresh_childs :: proc() {
	clear(&app.childs)
	app.curr_dir = to_cstr(os.get_current_directory())
	handle, _ := os.open(string(app.curr_dir), os.O_RDONLY)
	files, _  := os.read_dir(handle, 100)
	for file in files {
		append(&app.childs, file)
	}
}

render_app :: proc() {
	im.Begin("App")
	im.InputText("dir", app.curr_dir, 1024)

	if im.BeginTable("Directories", 1){
		im.TableSetupColumn("Name")
		im.TableHeadersRow()
		im.TableNextRow()
		im.TableNextColumn()

		if(im.Button("..")){
			os.change_directory("..")
			refresh_childs()
		}

		for &file in &app.childs{
			im.TableNextRow()
			im.TableNextColumn()
			if im.Button(to_cstr(file.name)){
				if file.is_dir{
					os.change_directory(file.fullpath)
					refresh_childs()
				}
			}
		}
		im.EndTable()
	}

	im.End()
}


main :: proc() {

	assert(sdl.Init(sdl.INIT_EVERYTHING) == 0)
	defer sdl.Quit()

	sdl.GL_SetAttribute(.CONTEXT_FLAGS, i32(sdl.GLcontextFlag.FORWARD_COMPATIBLE_FLAG))
	sdl.GL_SetAttribute(.CONTEXT_PROFILE_MASK, i32(sdl.GLprofile.CORE))
	sdl.GL_SetAttribute(.CONTEXT_MAJOR_VERSION, 3)
	sdl.GL_SetAttribute(.CONTEXT_MINOR_VERSION, 2)

	window := sdl.CreateWindow(
		"Dora",
		sdl.WINDOWPOS_CENTERED,
		sdl.WINDOWPOS_CENTERED,
		1270,
		720,
		{.OPENGL, .RESIZABLE, .ALLOW_HIGHDPI, .MOUSE_CAPTURE},
	)

	assert(window != nil)
	defer sdl.DestroyWindow(window)
	defer sdl.DestroyWindow(window)

	gl_ctx := sdl.GL_CreateContext(window)
	defer sdl.GL_DeleteContext(gl_ctx)

	sdl.GL_MakeCurrent(window, gl_ctx)
	sdl.GL_SetSwapInterval(1) //Vsync

	gl.load_up_to(3, 2, proc(p: rawptr, name: cstring) {
		(cast(^rawptr)p)^ = sdl.GL_GetProcAddress(name)
	})

	im.CHECKVERSION()
	im.CreateContext()
	defer im.DestroyContext()
	io := im.GetIO()

	io.ConfigFlags += {.NavEnableKeyboard}
	io.ConfigFlags += {.DockingEnable, .ViewportsEnable}

	im.FontAtlas_AddFontFromFileTTF(io.Fonts, "C:/Windows/Fonts/Consola.ttf", 15)
	style := im.GetStyle()
	style.WindowRounding = 0
	style.Colors[im.Col.WindowBg].w = 1

	im.StyleColorsClassic()

	im_sdl.InitForOpenGL(window, gl_ctx)
	defer im_sdl.Shutdown()
	im_gl.Init(nil)

	defer im_gl.Shutdown()

	running := true

	refresh_childs()

	fmt.println(os.get_current_directory())
	//fmt.println(os.change_directory(".."))
	fmt.println(os.get_current_directory())

	for running {
		e: sdl.Event
		for sdl.PollEvent(&e) {
			im_sdl.ProcessEvent(&e)

			#partial switch e.type {
			case .QUIT:
				running = false
			case .MOUSEWHEEL:
				if io.WantCaptureMouse{
					im.IO_AddMouseWheelEvent(io, f32(-e.wheel.x), f32(e.wheel.y))
				}
			}
		}

		im_gl.NewFrame()
		im_sdl.NewFrame()
		im.NewFrame()

		render_app()

		im.Render()
		gl.Viewport(0, 0, i32(io.DisplaySize.x), i32(io.DisplaySize.y))
		gl.ClearColor(0.4, 0.4, 0.2, 1)
		gl.Clear(gl.COLOR_BUFFER_BIT)
		im_gl.RenderDrawData(im.GetDrawData())

		backup_current_window := sdl.GL_GetCurrentWindow()
		backup_current_context := sdl.GL_GetCurrentContext()
		im.UpdatePlatformWindows()
		im.RenderPlatformWindowsDefault()
		sdl.GL_MakeCurrent(backup_current_window, backup_current_context)

		sdl.GL_SwapWindow(window)

	}

}
