module Flow

using DataStructures, HttpCommon, Morsel, JSON

app = Morsel.app()
state = {:console => {:input => "",
                      :output => ""},
         :dirty_queue => Queue(Array{Symbol,1})}


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
    "ok"
end

put(app, "/store") do req, res
    ks = map(symbol, split(urlparam(req, :keys), ' '))
    v = urlparam(req, :val)
    store(ks, v)
    "ok"
end

get(app, "/fetch") do req, res
    ks = map(symbol, split(urlparam(req, :keys), ' '))
    string(fetch(ks))
end

get(app, "/fetch-json") do req, res
    res.headers["Content-Type"] = mimetypes["json"]
    ks = map(symbol, split(urlparam(req, :keys), ' '))
    json(fetch(ks))
end

get(app, "/dirty") do req, res
    res.headers["Content-Type"] = mimetypes["json"]

    if isempty(state[:dirty_queue])
        json({:status => :empty})
    else
        ks = dequeue!(state[:dirty_queue])
        json({:status => :ready,
              :keys => ks,
              :val => fetch(ks)})
    end
end


## process
start() = Morsel.start(app, 8000)

function store(ks, v)
    assoc_in!(state, ks, v)
    mark_dirty!(ks)
end
fetch(ks) = get_in(state, ks)

function mark_dirty!(ks)
    enqueue!(state[:dirty_queue], ks)
end

eval_console() = store([:console, :output],
                       eval(parse(fetch([:console, :input]))))

end # module
