module Flow

using HttpCommon, Morsel

app = Morsel.app()

load_static(path) = open(readall, Pkg.dir("Flow") * "/" * path)

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
    ## res.headers["Content-Type"] = mimetypes["json"]
    text = urlparam(req, :text)
    ptext = parse(text)
    r = eval(ptext)
    string(r)
end

start() = Morsel.start(app, 8000)

end # module
