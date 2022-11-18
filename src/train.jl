using DataFrames
using Clustering
using CSV 
using Plots 
using StatsPlots
using Statistics
using Random
using ScikitLearn
using PyCall
@sk_import preprocessing: StandardScaler
@sk_import cluster: KMeans

df = DataFrame(CSV.File("./data/2021.csv",normalizenames =true),)

float_df = select(df, findall(col -> eltype(col) <: Float64, eachcol(df)))
float_df = float_df[:,Not(names(select(float_df, r"Explained")))]


function normalize_features(df)
    for col in names(df)
        df[!,col] = (df[!,col].-mean(df[!,col]))./std(df[!,col])
    end
    return df
end


#X = normalize_features(float_df)
select!(float_df, Not([:Standard_error_of_ladder_score, :Ladder_score_in_Dystopia, :Dystopia_residual,:upperwhisker, :lowerwhisker]))


X = fit_transform!(StandardScaler(), Matrix(float_df))

names(float_df)

size(input)

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

plot(wcss)

Random.seed!(123)
cluster =KMeans(n_clusters=3)

cluster.fit(X)

cluster.labels_
cluster.inertia_
cluster.cluster_centers_

ClusteringResult(result)

scatter(df.Social_support, df.Healthy_life_expectancy, marker_z = cluster.labels_)

df.cluster = cluster.labels_

df.cluster

filter(row ->row.cluster ==0,df).Country_name

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


n = length(countries)
hm = GeoMakie.poly!(ax, countries; color= 1:n, colormap = :dense,
    strokecolor = :black, strokewidth = 0.5,
)
GeoMakie.translate!(hm, 0, 0, 100) # move above surface plot

save("../01-happines/img/map.png", fig)
