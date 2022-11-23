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
                           :Ladder_score, #Delete happiness score 
                           :Ladder_score_in_Dystopia, 
                           :Dystopia_residual]))
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
   yaxis = "Wcss",
  label = false)

savefig("./img/elbow.png")

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
        legend = false,
        size = (1000,800),
        xaxis = "Social Support",
        yaxis = "Ladder Score",
        title = "Comparison between social support and ladder score by country incorporating clustering")

savefig("./img/cluster-scatter.png")

df.cluster = cluster.labels_ .+1

filter(row ->row.cluster ==2,df).Country_name

histogram(filter(row ->row.cluster ==1,df).Ladder_score, label = "cluster 1", title = "Distribution of Happiness Score by Cluster", xaxis = "Ladder Score", yaxis="n° countries")
histogram!(filter(row ->row.cluster ==2,df).Ladder_score, label = "cluster 2")
histogram!(filter(row ->row.cluster ==3,df).Ladder_score, label = "cluster 3")

savefig("./img/distribution.png")

filter(row ->row.Country_name =="Chile",df).cluster

float_df = float_df[:,Not(names(select(float_df, r"Explained")))]
N = ncol(float_df)
numerical_cols = Symbol.(names(float_df,Real))
@df float_df Plots.density(cols();
                             layout=N,
                             size=(1600,1200),
                             title=permutedims(numerical_cols),
                             group = df.cluster,
                             label = false)

savefig("./img/distr_cluster_vars.png")



