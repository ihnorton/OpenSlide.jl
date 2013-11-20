const los = "libopenslide"

type openslide_t
end

typealias OSt Ptr{openslide_t}

const OPENSLIDE_PROPERTY_NAME_COMMENT = "openslide.comment"
const OPENSLIDE_PROPERTY_NAME_VENDOR = "openslide.vendor"
const OPENSLIDE_PROPERTY_NAME_QUICKHASH1 = "openslide.quickhash-1"
const OPENSLIDE_PROPERTY_NAME_BACKGROUND_COLOR = "openslide.background-color"
const OPENSLIDE_PROPERTY_NAME_OBJECTIVE_POWER = "openslide.objective-power"
const OPENSLIDE_PROPERTY_NAME_MPP_X = "openslide.mpp-x"
const OPENSLIDE_PROPERTY_NAME_MPP_Y = "openslide.mpp-y"

type OpenSlideImage
    img::Ptr{openslide_t}
end

function property_names(s::OSt)
    nms = ccall( (:openslide_get_property_names, los), Ptr{Ptr{Uint8}}, (OSt,), s)
    rv = Any[]
    i = 1 
    while (n = unsafe_load(nms,i)) != C_NULL
        push!(rv, bytestring(n))
        i += 1
    end
    rv 
end

function property_value(s::OSt, prop::ASCIIString)
    bytestring( ccall( (:openslide_get_property_value, los), Ptr{Uint8}, (OSt, Ptr{Uint8}), s, prop))
end

can_open(fname::ASCIIString) = ccall( (:openslide_can_open, los), Cint, (Ptr{Uint8},), fname) == 1 ? true : false

open(fname::ASCIIString) = ccall( (:openslide_open, los), Ptr{openslide_t}, (Ptr{Uint8},), fname)
levelcount(s::OSt) = ccall( (:openslide_get_level_count, los), Cint, (OSt,), s)

function root_dimensions(s::OSt)
    w = Int64[0]
    h = Int64[0]
    ccall( (:openslide_get_level0_dimensions, los), Void, (Ptr{openslide_t}, Ptr{Int64}, Ptr{Int64}), s, w, h)
    return [w, h]
end
    
function level_dimensions(s::OSt, dim::Int)
    w = Int[0]
    h = Int[0]
    ccall( (:openslide_get_level_dimensions, los), Void, (Ptr{openslide_t}, Int, Ptr{Cint}, Ptr{Cint}), s, dim, w, h)
    return [w,h]
end


level_downsample(s::OSt, level) = ccall( (:openslide_get_level, los), Cdouble, (Ptr{openslide_t}, Cint), s, level)


function get_best_downsample_level(s::OSt, factor::Cdouble)
    ccall( (:openslide_get_best_level_for_downsample, los), Cint, (OSt, Cdouble), s, factor)
end

function read_region(img::OSt, x, y, level, w, h)
    # allocate memory to hold output
    data = zeros(Int32, w*h)
    ccall( (:openslide_read_region, los),
            Void,
            (OSt, Ptr{Cint}, Int64, Int64, Int32, Int64, Int64),
            img, data, x, y, int32(level), w, h)
    data
#    read_region(img, data, x,y,level,w,h)
end

last_error(img::OSt) = bytestring(ccall( (:openslide_get_error, los), Ptr{Uint8}, (OSt,), img))

version() = bytestring(ccall( (:openslide_get_version,los),Ptr{Uint8}, ()))
