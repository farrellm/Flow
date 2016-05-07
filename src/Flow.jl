module Flow

using DataStructures, HttpCommon, Morsel, JSON, Logging

app = Morsel.app()
state = {:console => {:input => "",
                      :output => ""},

         :tabs => {{:id => -1,
                    :name => "test"
                    :values => [{:name => "x",
                                 :type => :constant,
                                 :value => 8
                                 }]}},
         :next_tab_id => 0,
         :active_tab_id => -1,

         :dirty_queue => {}
         }


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
get(app, "/eval") do req, res
    res.headers["Content-Type"] = mimetypes["json"]
    text = decodeURI(urlparam(req, :text))
    info("EVAL " * text)
    ptext = parse(text)
    json({:value => eval(ptext)})
end

put(app, "/store") do req, res
    ks = map(symbol, split(urlparam(req, :keys), ' '))
    v = decodeURI(urlparam(req, :val))
    if v == None
        println("none")
        v = ""
    end
    info(@sprintf("STORE %s => %s (%s)", ks, v, typeof(v)))
    store_silent!(ks, v)
    "ok"
end

get(app, "/fetch") do req, res
    res.headers["Content-Type"] = mimetypes["json"]
    ks = map(symbol, split(urlparam(req, :keys), ' '))
    info(@sprintf("FETCH %s", ks))
    json({:value => fetch(ks)})
end

get(app, "/dirty") do req, res
    res.headers["Content-Type"] = mimetypes["json"]

    if isempty(state[:dirty_queue])
        json({:status => :empty})
    else
        ks = shift!(state[:dirty_queue])
        res = json({:status => :ready,
              :keys => ks,
              :value => fetch(ks)})
        info(@sprintf("DIRTY %s", ks))
        debug(@sprintf("DIRTY => %s", res))
        res
    end
end


## process
function start(loglevel=INFO)
    Logging.configure(level=loglevel)
    Morsel.start(app, 8080)
end

function store_silent!(ks, v)
    debug(@sprintf("store_silent! %s => %s", ks, v))
    assoc_in!(state, ks, v)
end
function store!(ks, v)
    debug(@sprintf("store! %s => %s", ks, v))
    store_silent!(ks, v)
    mark_dirty!(ks)
end
fetch(ks) = get_in(state, ks)

function mark_dirty!(ks)
    push!(state[:dirty_queue], ks)
end

function sshow(val)
    ## http://thenewphalls.wordpress.com/2014/03/21/capturing-output-in-julia/
    originalSTDOUT = STDOUT
    (outRead, outWrite) = redirect_stdout()
    show(val)
    close(outWrite)
    
    data = readavailable(outRead)
    close(outRead)
    redirect_stdout(originalSTDOUT)
    
    data
end

eval_console() = store!([:console, :output],
                        sshow(eval(parse(fetch([:console, :input])))))

function new_tab(name)
    ts = fetch([:tabs])
    id = fetch([:next_tab_id])
    store_silent!([:next_tab_id], id + 1)

    info(@sprintf("new_tab: '%s' (%i)", name, id))

    push!(ts, {:id => id,
               :name => name,
               :active => true})

    store!([:tabs], ts)
    id
end

find_named(ms, n) = filter(m-> m[:name] == n, ms)

function tab_value(tab, value)
    tabs = find_named(state[:tabs], tab)
    if length(tabs) == 0
        throw("no such tab " * tab)
    elseif length(tabs) > 1
        throw("multiple tabs named " * tab)
    end
    
    vals = find_named(tabs[1], value)
    if length(vals) == 0
        throw("no such value " * value)
    elseif length(vals) > 1
        throw("multiple values named " * value)
    end

    vals[1]
end

end # module
