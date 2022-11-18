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

Random.seed!(123)
cluster =KMeans(n_clusters=3)

cluster.fit(X)

cluster.labels_
cluster.inertia_
cluster.cluster_centers_

ClusteringResult(result)

scatter(df.Social_support, df.Healthy_life_expectancy, marker_z = cluster.labels_)

df.cluster = result.assignments


