using DataFrames
using Clustering
using CSV 
using Plots 
using StatsPlots
using Statistics

df = DataFrame(CSV.File("./data/2021.csv",normalizenames =true),)

float_df = select(df, findall(col -> eltype(col) <: Float64, eachcol(df)))

 kmeans(float_df, 3, maxiter=200, display=:iter)

function normalize_features(df)
    for col in names(df)
        df[!,col] = (df[!,col].-mean(df[!,col]))./std(df[!,col])
    end
    return df
end

float_df=normalize_features(float_df)

names((float_df)

float_df.Healthy_life_expectancy

histogram(float_df.Healthy_life_expectancy)

R = kmeans(Matrix(float_df), 3, maxiter=200, display=:iter)

assignments(R)
counts(R)
R.centers

R.assignments
