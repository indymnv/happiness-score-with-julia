using DataFrames
using Clustering
using CSV 
using Plots 
using StatsPlots
using Statistics
using Random
using ScikitLearn
using PyCall
Plots.theme(:ggplot2)
@sk_import preprocessing: StandardScaler
@sk_import cluster: KMeans

function read_file()
    df = DataFrame(CSV.File("./data/2021.csv",normalizenames =true),)

    float_df = select(df, findall(col -> eltype(col) <: Float64, eachcol(df)))
    float_df = float_df[:,Not(names(select(float_df, r"Explained")))]   
    select!(float_df, Not([:Standard_error_of_ladder_score, 
                           :Ladder_score_in_Dystopia, 
                           :Dystopia_residual,:upperwhisker,
                           :lowerwhisker]))
    return float_df, df
end

float_df, df = read_file()

function kmeans_train(df)
    X = fit_transform!(StandardScaler(), Matrix(df))

    wcss = []
    for n in 1:10

        Random.seed!(123)
        cluster =KMeans(n_clusters=n,
                        init = "k-means++",
                        max_iter = 20,
                        n_init = 10,
                        random_state = 0)
        cluster.fit(X)
        push!(wcss, cluster.inertia_)
    end
    return wcss
end

wcss = kmeans_train(float_df)

plot(wcss, title = "wcss in each cluster",
    xaxis = "cluster",
   yaxis = "Wcss")

#Decide the number of clusters with elbow curve, in my case i choose 3

function kmeans_train(df, n)
    X = fit_transform!(StandardScaler(), Matrix(df))

    Random.seed!(123)
    cluster =KMeans(n_clusters=n,
                    init = "k-means++",
                    max_iter = 20,
                    n_init = 10,
                    random_state = 0)
    cluster.fit(X)
    return cluster
end

cluster= kmeans_train(float_df, 3)

scatter(df.Social_support,
        df.Ladder_score,
        marker_z = cluster.labels_,
        xaxis = "Social Support",
        yaxis = "Happiness Score",
        title = "Clustering of countries by Happiness factors")

df.cluster = cluster.labels_

filter(row ->row.cluster ==0,df).Country_name

histogram(filter(row ->row.cluster ==0,df).Ladder_score)
histogram!(filter(row ->row.cluster ==1,df).Ladder_score)
histogram!(filter(row ->row.cluster ==2,df).Ladder_score)


filter(row ->row.Country_name =="Chile",df).cluster

import GeoMakie, CairoMakie

# First, make a surface plot
lons = -180:180
lats = -90:90
field = [exp(cosd(l)) + 3(y/90) for l in lons, y in lats]

fig = CairoMakie.Figure()
ax = GeoAxis(fig[1,1])
sf = GeoMakie.surface!(ax, lons, lats, field; shading = false)
cb1 = Colorbar(fig[1,2], sf; label = "field", height = Relative(0.65))

using GeoMakie.GeoJSON
countries_file = download("https://datahub.io/core/geo-countries/r/countries.geojson")
countries = GeoJSON.read(read(countries_file, String))

df_world = DataFrame(countries)

rename!(df, :Country_name => :ADMIN)

df_world = leftjoin(df_world, df[!,[:ADMIN, :cluster]], on =:ADMIN)

df_world = coalesce.(df_world, -1)

df_world[!,:cluster] =string.(df_world[!,:cluster])

replace!(df_world.cluster, "-1" => "gray",
                    "0" => "red",
                   "1" => "green",
                   "2" => "yellow")

n = length(countries)

hm = GeoMakie.poly!(ax, df_world;
                    color= df_world.cluster, colormap = :dense,
    strokecolor = :black, strokewidth = 0.5,
)
GeoMakie.translate!(hm, 0, 0, 100) # move above surface plot

save("../01-happines/img/map.png", fig)



