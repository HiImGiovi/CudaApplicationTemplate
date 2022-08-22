require("premake5-cuda")
include ("Dependencies.lua")

 workspace "CudaApp"  
    configurations { "Debug", "Release", "Dist"} 
    architecture("x86")
    outputdir = "%{cfg.buildcfg}-%{cfg.system}-%{cfg.architecture}"
        project "CudaApp"  
        location "CudaApp"
        kind "ConsoleApp"   
        language "C++"   
        targetdir ("bin/" .. outputdir .. "/%{prj.name}/") 
        objdir ("bin-obj/" .. outputdir .. "/%{prj.name}/") 
        files
        { 
            "%{prj.name}/src/**.hpp",
            "%{prj.name}/src/**.cpp",
        } 

        includedirs
        {
            "%{IncludeDir.GLFW}",
            "%{IncludeDir.Glad}"
        }
        links
        {
            "opengl32.lib",
            "GLFW",
            "Glad", 
        }
        
        -- Add necessary build customization using standard Premake5
        -- This assumes you have installed Visual Studio integration for CUDA
        -- Here we have it set to 11.4
        buildcustomizations "BuildCustomizations/CUDA 11.7"
        cudaPath "/usr/local/cuda" -- Only affects linux, because the windows builds get CUDA from the VS extension
        
        -- CUDA specific properties
        cudaFiles {
            "CudaApp/src/*.cu",
            "CudaApp/src/*.h"
        } -- files NVCC compiles
        cudaMaxRegCount "32"
        
        -- Let's compile for all supported architectures (and also in parallel with -t0)
        cudaCompilerOptions {"-arch=sm_52", "-gencode=arch=compute_52,code=sm_52", "-gencode=arch=compute_60,code=sm_60",
        "-gencode=arch=compute_61,code=sm_61", "-gencode=arch=compute_70,code=sm_70",
        "-gencode=arch=compute_75,code=sm_75", "-gencode=arch=compute_80,code=sm_80",
        "-gencode=arch=compute_86,code=sm_86", "-gencode=arch=compute_86,code=compute_86", "-t0"}                      
        
        -- On Windows, the link to cudart is done by the CUDA extension, but on Linux, this must be done manually
        if os.target() == "linux" then 
            linkoptions {"-L/usr/local/cuda/lib64 -lcudart"}
        end
        filter "system:Windows"
            defines{
                "GLFW_INCLUDE_NONE"
            }
        
        filter "configurations:Debug"
        defines { "DEBUG" }  
        symbols "On" 
        filter "configurations:Release"  
        optimize "On" 
        cudaFastMath "On" -- enable fast math for release
        filter ""
        
        group "Dependencies"
            include ("CudaApp/vendor/GLFW")
            include ("CudaApp/vendor/Glad")

        group ""




