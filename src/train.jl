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

