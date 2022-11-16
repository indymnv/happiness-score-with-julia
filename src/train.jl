using DataFrames
using Clustering
using CSV 
using Plots 
using StatsPlots
using Statistics
using Random
using ScikitLearn

df = DataFrame(CSV.File("./data/2021.csv",normalizenames =true),)

float_df = select(df, findall(col -> eltype(col) <: Float64, eachcol(df)))

float_df = float_df[:,Not(names(select(float_df, r"Explained")))]

function normalize_features(df)
    for col in names(df)
        df[!,col] = (df[!,col].-mean(df[!,col]))./std(df[!,col])
    end
    return df
end

float_df=normalize_features(float_df)
select!(float_df, Not([:Standard_error_of_ladder_score, :Ladder_score_in_Dystopia, :Dystopia_residual,:upperwhisker, :lowerwhisker]))

names(float_df)

input = reshape(Matrix(float_df), (7,149))

size(input)

Random.seed!(123)
result = kmeans(input, 3, maxiter=200, display=:iter)

ClusteringResult(result)

scatter(df.Social_support, df.Healthy_life_expectancy, marker_z = result.assignments)

df.cluster = result.assignments

names(df)

filter(row -> row.cluster ==2 , df).Country_name
