module OpenSlide

include("../deps/deps.jl")

export
    OpenSlideImage,
    AssociatedImage,
    open_slide,
    level_dims,
    read_slide,
    properties,
    associated_images,
    read_associated

immutable openslide_t end
typealias OSt Ptr{openslide_t}

type OpenSlideImage
    file::String
    levels::Int
    leveldims
    osptr::Ptr{openslide_t}

    OpenSlideImage(file,levels,dims,osptr) = new(file,int(levels),dims,osptr)
end
# TODO finalizer

type AssociatedImage
    name::String
    dims::Array{Int,1}
    primary::OpenSlideImage
end

################################################################################
include("libopenslide.jl")
################################################################################

function open_slide(file::ASCIIString)
    osptr = openslide_open(file)
    (osptr == C_NULL) && error("Unrecognized slide file: ", file)
    
    levels = get_level_count(osptr)
    dims = Array{Int,1}[]
    for level in 1:levels
        push!(dims, get_level_dimensions(osptr,level-1))
    end

    return OpenSlideImage(file,levels,dims,osptr)
end

function level_dims(img::OpenSlideImage, level::Int)
    get_level_dimensions(img.osptr, level)
end

function read_slide(img::OpenSlideImage; level = -1, origin = [0,0], extent = None)
    if (level < 0)
        level = 1 
    end
    if (extent == None)
        extent = img.leveldims[level]
    end
    read_region(img.osptr, origin..., level, extent...)
end

function properties(img::OpenSlideImage)
    rv = Dict{ASCIIString,ASCIIString}()
    for name in get_property_names(img.osptr)
        rv[name] = get_property_value(img.osptr,name)
    end
    return rv
end

function associated_images(img::OpenSlideImage)
    rv = AssociatedImage[]
    for name in associated_names(s)
        dims = associated_dimensions(name)
        push!(rv, AssociatedImage(name, dims))
    end
end

function read_associated(img::AssociatedImage)
    read_associated_image(img.primary.osptr, img.name, img.dims)
end

end # module
