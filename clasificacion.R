library(dplyr)
library(naivebayes)
library(ggplot2)


remove(list = ls())


setwd("/home/marlon/mainfolder/marlon/USFQ/DataMining/5_Clasificacion/P5")


#Escoger training y test data sets
dataset = readRDS("SPECTF_FINAL.rds")

dataset$OVERALL_DIAGNOSIS = as.factor(dataset$OVERALL_DIAGNOSIS)

summary(dataset)

(N = nrow(dataset))

target = round(N * 0.75)

gp = runif(N)

train_data = dataset[gp < 0.75,]
test_data = dataset[gp >= 0.75,]

#Data normalizada Min-Max
train_data_n = train_data
for(i in 2:ncol(train_data_n)){
    train_data_n[i] =  (train_data_n[i] - min(train_data_n[i]))/ (max(train_data_n[i]) - min(train_data_n[i])) * (1-0) + 0
}

test_data_n = test_data

for(i in 2:ncol(train_data_n)){
    test_data_n[i] =  (test_data_n[i] - min(test_data_n[i]))/ (max(test_data_n[i]) - min(test_data_n[i])) * (1-0) + 0
}


#Naive Bayes

train_data_n$OVERALL_DIAGNOSIS = as.factor(train_data_n$OVERALL_DIAGNOSIS)

model = naive_bayes(OVERALL_DIAGNOSIS ~ ., data = train_data_n)

pred_data = predict(model, newdata = test_data_n[-1])

actual_pred = test_data_n$OVERALL_DIAGNOSIS

table(pred_data, actual_pred)

(naive_bayes_performance = mean(pred_data == actual_pred))


#Knn con distancia euclidiana

my_knn = function(y, train_data, test_data, dist, k){
    data_test = train_data
    
    data_test$distance = 0
    
    test = test_data
    
    column_names = names(test)
    
    predictions = c()
    
    for(ob in 1:nrow(test)){
        
        observacion = test[ob,]
        
        if(dist == "euclidean"){
            for(col in column_names){
                data_test = data_test %>%
                    mutate(distance = distance + (data_test[col] - as.numeric(observacion[1, col]))^2 )
            }
            data_test = data_test %>%
                mutate(distance = sqrt(distance))
        }else if(dist == "manhattan"){
            for(col in column_names){
                data_test = data_test %>%
                    mutate(distance = distance + abs(data_test[col] - as.numeric(observacion[1, col])))
            }
        }
        
        chose_data = data_test %>%
            top_n(distance, n = -k) %>%
            group_by(eval(parse(text = y))) %>%
            summarise(n = n()) %>%
            arrange(desc(n))
        
        prediction = as.numeric(chose_data[1,1]) - 1

        predictions = c(predictions, prediction)
    }
    
    predictions = c(predictions, c(0,1))
    predictions = as.factor(predictions)
    
    predictions = head(predictions,-2)
    
    return(predictions)
}


my_pred_euclidean = my_knn("OVERALL_DIAGNOSIS", train_data_n, test_data_n[-1],"euclidean", k = 5)
my_pred_manhattan = my_knn("OVERALL_DIAGNOSIS", train_data_n, test_data_n[-1],"manhattan", k = 5)
mean(my_pred_euclidean == actual_pred)
mean(my_pred_manhattan == actual_pred)

#Rendimiento con distintas Ks

performance_ks = function(k1, k2, y, dist, real_data){
    ks = seq(k1, k2, 2)
    
    k_number = c()
    accuracy = c()
    
    for(k in ks){
        k_number = c(k_number, k)
        knn = my_knn(y, train_data_n, test_data_n[-1],dist, k = k)
        accuracy = c(accuracy, mean(knn == real_data))
    }
    
    k_accuracy = data.frame(k_number, accuracy)
    
    k_accuracy = k_accuracy %>%
        arrange(desc(accuracy), k_number)
    
    return(k_accuracy)
}

performance_ecludian = performance_ks(1,30, "OVERALL_DIAGNOSIS", "euclidean", actual_pred)

performance_manhattan = performance_ks(1,30, "OVERALL_DIAGNOSIS", "manhattan", actual_pred)

performance_ecludian$distance = "Euclidean"
performance_manhattan$distance = "Manhattan"

general_performace = rbind(performance_ecludian, performance_manhattan)

ks = seq(1, 30, 2)

ggplot(general_performace, aes(y = accuracy , x = k_number, color = distance)) +
    geom_line()+
    scale_x_continuous("K", labels = as.character(ks), breaks = ks) +
    labs(title = "Rendimiento con Knn(Euclidean vs Manhattan)")
    theme_bw()
    
sprintf("Naive Bayes Performance: %s", naive_bayes_performance)
    
sprintf("Knn performance (Euclidean): k = %s, %s", performance_ecludian[1,1], performance_ecludian[1,2])

sprintf("Knn performance (Manhattan): k = %s, %s", performance_manhattan[1,1], performance_manhattan[1,2])


    


