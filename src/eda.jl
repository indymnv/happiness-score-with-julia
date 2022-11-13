using DataFrames
using CSV
using Turing
using Plots
using StatsPlots
using Statistics
theme(:ggplot2)

df_2021 = DataFrame(CSV.File("./data/2021.csv", normalizenames=true))
df_all = DataFrame(CSV.File("./data/world-happiness-report.csv", normalizenames=true))

#Describe
print(describe(df_2021))

#columns
names(df_2021)

scatter(
    df_2021.Social_support,
    df_2021.Healthy_life_expectancy,
    group = df_2021.Regional_indicator, 
    #label =df_2021.Regional_indicator
    legend = :topleft,
)

#Counting countries by region

sort(
    combine(groupby(df_2021, :Regional_indicator), nrow), 
    :nrow
)

unique(df_2021.Regional_indicator)

#Distribution of each variable
float_df = select(df_2021, findall(col -> eltype(col) <: Float64, eachcol(df_2021)))


#Take away the Explained variables
float_df = float_df[:,Not(names(select(float_df, r"Explained")))]
N = ncol(float_df)
numerical_cols = Symbol.(names(float_df,Real))
@df float_df Plots.histogram(cols();
                             layout=N,
                             size=(2300,1200),
                             title=permutedims(numerical_cols),
                             label = false)

#Understand what is explained in variables in boxplots
@df float_df boxplot(cols(), 
                     fillalpha=0.75, 
                     linewidth=2, 
                     legend = :topleft)

# Top 5 and bottom 5 countries by ladder score
sort!(df_2021, :Ladder_score, rev=true)
plot(
    bar(
        first(df_2021.Country_name, 5 ),
        first(df_2021.Ladder_score, 5 ),
        #yerror = 0.3,#first(df_2021.Standard_error_of_ladder_score, 5 ),
        color= "green",
        title = "Top 5 of countries by Happiness score",
        legend = false,
    ),
    bar(
        last(df_2021.Country_name, 5 ),
        last(df_2021.Ladder_score, 5 ),
        color ="red",
        title = "Bottom 5 of countries by Happiness score",
        legend = false,
    ),
size=(1000,800),
yaxis = "Happines Score",
)

# selecting strings
str_df = select(df_2021, findall(col -> eltype(col) <: String, eachcol(df_2021)))

#Take away the Explained variables
float_df = float_df[:,Not(names(select(float_df, r"Explained")))]

# pairplot for float variables
@df float_df cornerplot(cols(1:N), grid = true, size=(3500, 3500), compact = true)

# heavy intensive so better to get correlation in numbers instead of images
cm = cor(Matrix(float_df))
high = findall(x -> abs(x) > 0.75 && abs(x) < 1.0, cm)
couple_var= [[names(float_df,idx.I[1]); names(float_df, idx.I[2]);] for idx in high]

var_1 =[]
var_2 =[]
for i in eachindex(couple_var)
    var_1 = push!(var_1, couple_var[i][1])
    var_2 = push!(var_2, couple_var[i][2])
end
var_1
var_2
values = cm[findall(x -> abs(x) > 0.75 && abs(x) < 1.0, cm)]

corr_df = DataFrame("var1" => var_1,
                    "var2" => var_2, 
                    "corr" => values)

sort!(corr_df, :corr, rev=true)
corr_df

#Select only variables considered for analysis (avoiding explained)
function distribution_plot(df, var_filter, list_elements)
    display(
        @df df density(:Ladder_score,
        legend = :topleft, size=(1000,800) , 
        fill=(0, .3,:yellow),
        label="Distribution" ,
        xaxis="Happiness Index Score", 
        yaxis ="Density", 
        title ="Happiness index score 2021") 
    )
    display(
        plot!([mean(df_2021.Ladder_score)],
        seriestype="vline",
        line = (:dash), 
        lw = 3,
        label="Mean")
    )
    for element in list_elements
        display(
            plot!(
            mean([filter(row->row[var_filter]==element, df).Ladder_score]),
            seriestype="vline",
            lw = 3,
            label="$element") 
        )
    end

    
end

#Ladder score distribution with some Regional_indicator
distribution_plot(df_2021, "Country_name", ["Chile",
                                            "United States",
                                            "Spain",
                                            "Japan",
                                            "Brazil",
                                            "China",
                                           ])

#Select only variables considered for analysis Regional_indicator
function distribution_plot(df)
    display(
        @df df density(:Ladder_score,
        legend = :topleft, size=(1000,800) , 
        fill=(0, .3,:yellow),
        label="Distribution" ,
        xaxis="Happiness Index Score", 
        yaxis ="Density", 
        title ="Happiness Index Score by Region 2021") 
    )
    display(
        plot!([mean(df_2021.Ladder_score)],
        seriestype="vline",
        line = (:dash), 
        lw = 3,
        label="Mean")
    )
    for element in unique(df_2021.Regional_indicator)
        display(
            plot!(
            [mean(mean([filter(row->row["Regional_indicator"]==element, df).Ladder_score]))],
            seriestype="vline",
            lw = 3,
            label="$element") 
        )
    end

    
end


distribution_plot(df_2021)

#savefig("./img/felicidad_paises.png")

plot(filter(row -> row.Country_name == "Japan", df_all).year,
filter(row -> row.Country_name == "Japan", df_all).Life_Ladder, label="Japan")
plot!(filter(row -> row.Country_name == "Chile", df_all).year,
filter(row -> row.Country_name == "Chile", df_all).Life_Ladder, label="Chile")

#Plot countries with larger gap score across the time

#Plot average across the Regional_indicator and see changes in time

#Box plot with all Regional_indicator ladder_score


#build a clustering model with kmeans or another to see groups in every single cluster


#values[values .>= 1.0]
