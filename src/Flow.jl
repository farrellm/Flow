module Flow

using HttpCommon, Morsel, JSON


app = Morsel.app()
state = {:console => {:input => "",
                      :output => ""}}


## utility
load_static(path) = open(readall, Pkg.dir("Flow") * "/" * path)

function get_in(m, ks)
    n = m
    for k = ks
        n = n[k]
    end
    n
end

function assoc_in(m, ks, v)
    merge(m, assoc_in(m, ks, v, 1))
end
function assoc_in(m, ks, v, i)
    if i < length(ks)
        if haskey(m, ks[i])
            merge(m, assoc_in(m[ks[i]], ks, v, i+1))
        else
            n = [ks[i] => assoc_in(Dict(), ks, v, i+1)]
            merge(m, n)
        end
    else
        merge(m, {ks[end] => v})
    end
end

function assoc_in!(m, ks, v)
    n = m
    for k = ks[1:end-1]
        if !haskey(n, k)
            n[k] = Dict()
        end
        n = n[k]
    end
    n[ks[end]] = v
end


## rest
get(app, "/static/html/<path::%.*>") do req, res
    load_static("html/" * routeparam(req, :path))
end

get(app, "/static/css/<path::%.*>") do req, res
    res.headers["Content-Type"] = mimetypes["css"]
    load_static("html/css/" * routeparam(req, :path))
end

get(app, "/static/images/<path::%.*>") do req, res
    res.headers["Content-Type"] = mimetypes["png"]
    load_static("html/images/" * routeparam(req, :path))
end

get(app, "/static/js/<path::%.*>") do req, res
    res.headers["Content-Type"] = mimetypes["js"]
    load_static("html/js/" * routeparam(req, :path))
end

get(app, "/eval") do req, res
    res.headers["Content-Type"] = mimetypes["json"]
    text = urlparam(req, :text)
    ptext = parse(text)
    r = eval(ptext)
    json(r)
end

put(app, "/store") do req, res
    ks = map(symbol, split(urlparam(req, :keys), ' '))
    v = urlparam(req, :val)
    store(ks, v)
    "ok"
end

get(app, "/fetch") do req, res
    res.headers["Content-Type"] = mimetypes["json"]
    ks = map(symbol, split(urlparam(req, :keys), ' '))
    json(fetch(ks))
end


## process
start() = Morsel.start(app, 8000)

store(ks, v) = assoc_in!(state, ks, v)
fetch(ks) = get_in(state, ks)

eval_console() = store([:console, :output],
                       eval(parse(fetch([:console, :input]))))

end # module
