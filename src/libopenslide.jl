#TODO exports
#    get_property_names,
#    get_property_value,
#    can_open,
#    openslide_open,
#    get_level_count,
#    close_slide,
#    get_level0_dimensions,
#    get_level_dimensions,
#    get_level_downsample,
#    get_best_level_for_downsample,
#    read_region,
#    get_associated_image_names,
#    read_associated_image,
#    get_error,
#    openslide_version

################################################################################

const OPENSLIDE_PROPERTY_NAME_COMMENT = "openslide.comment"
const OPENSLIDE_PROPERTY_NAME_VENDOR = "openslide.vendor"
const OPENSLIDE_PROPERTY_NAME_QUICKHASH1 = "openslide.quickhash-1"
const OPENSLIDE_PROPERTY_NAME_BACKGROUND_COLOR = "openslide.background-color"
const OPENSLIDE_PROPERTY_NAME_OBJECTIVE_POWER = "openslide.objective-power"
const OPENSLIDE_PROPERTY_NAME_MPP_X = "openslide.mpp-x"
const OPENSLIDE_PROPERTY_NAME_MPP_Y = "openslide.mpp-y"

################################################################################

function _rgbfromrowflat(data::Array{Uint8,1}, dims)
    output = zeros(Uint8, *(dims...),3)
    @inbounds for i = 1:3
        output[:,i] = data[-(i-4):4:end]
    end
    return reshape(output, dims...,3)
end
function _readstrings(buf::Ptr{Ptr{Uint8}})
    rv = Any[]
    i = 1 
    while (n = unsafe_load(buf,i)) != C_NULL
        push!(rv, bytestring(n))
        i += 1
    end
    return rv
end

################################################################################

function get_property_names(s::OSt)
    nms = ccall( (:openslide_get_property_names, los),
                 Ptr{Ptr{Uint8}}, (OSt,), s)
    _readstrings(nms)
end

function get_property_value(s::OSt, prop::ASCIIString)
    bytestring( ccall( (:openslide_get_property_value, los), Ptr{Uint8}, (OSt, Ptr{Uint8}), s, prop))
end

function can_open(fname::ASCIIString)
    ccall( (:openslide_can_open, los), Cint, (Ptr{Uint8},), fname) == 1 ? true : false
end

function openslide_open(fname::ASCIIString)
    ccall( (:openslide_open, los), Ptr{openslide_t}, (Ptr{Uint8},), fname)
end

function get_level_count(s::OSt)
    ccall( (:openslide_get_level_count, los), Cint, (OSt,), s)
end

function close_slide(s::OSt)
    ccall( (:openslide_close, los), Cint, (OSt,), s)
end

function get_level0_dimensions(s::OSt)
    w = Int64[0]
    h = Int64[0]
    ccall( (:openslide_get_level0_dimensions, los), Void, (Ptr{openslide_t}, Ptr{Int64}, Ptr{Int64}), s, w, h)
    return [w, h]
end
    
function get_level_dimensions(s::OSt, level::Int)
    w = Int[0]
    h = Int[0]
    ccall( (:openslide_get_level_dimensions, los),
            Void,
            (Ptr{openslide_t}, Int, Ptr{Cint}, Ptr{Cint}),
            convert(Ptr{openslide_t}, s), level, pointer(w), pointer(h))
    return [w,h]
end


function get_level_downsample(s::OSt, level)
    ccall( (:openslide_get_level_downsample, los),
            Cdouble,
            (Ptr{openslide_t}, Cint),
            s, level)
end

function get_best_level_for_downsample(s::OSt, factor::Cdouble)
    ccall( (:openslide_get_best_level_for_downsample, los),
            Cint, (OSt, Cdouble),
            s, factor)
end

function _read_region(img::OSt, data, x, y, level, w, h)
    ccall( (:openslide_read_region, los),
            Void,
            (OSt, Ptr{Cint}, Int64, Int64, Int32, Int64, Int64),
            img, data, x, y, int32(level-1), w, h)
end

function read_region(img::OSt, x, y, level, w, h)
    # allocate memory to hold output
    data = zeros(Uint32, w*h)
    _read_region(img, data, x, y, level, w, h)
    return _rgbfromrowflat(reinterpret(Uint8,data), [w, h])
end

function get_associated_image_names(s::OSt)
    buf = ccall( (:openslide_get_associated_image_names, los), Ptr{Ptr{Uint8}}, (OSt,))
    _readstrings(buf)
end    

function get_associated_image_dimensions(s::OSt, name::ASCIIString)
    w = h = Int64[0]
    ccall( (:openslide_get_associated_image_dimensions, los),
            Void, (OSt, Ptr{Cchar}, Ptr{Clong}, Ptr{Clong}),
            s, name, w, h)
    return [w,h]
end

function read_associated_image(img::OSt, name::ASCIIString, dims)
    data = zeros(Uint32, *(dims...), 4)
    ccall( (:openslide_read_associated_image, los), Void,
            (OSt, Ptr{Cchar}, Ptr{Cuint}),
            osptr, name, data)
    return _rgbfromrowflat(data, dims)
end

function get_error(img::OSt)
    bytestring(ccall( (:openslide_get_error, los), Ptr{Uint8}, (OSt,), img))
end

function openslide_version()
    bytestring(ccall( (:openslide_get_version,los),Ptr{Uint8}, ()))
end

