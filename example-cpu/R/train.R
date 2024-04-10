library(torch)

args <- commandArgs(trailingOnly = TRUE)
input_filename <- args[1]

messidor_data <- read.csv(input_filename, header = FALSE, skip = 24) # skip the header of .arff file

messidor_dataset <- dataset(
    name = "messidor",
    initialize = function() {
        input <- as.matrix(messidor_data)
        self$data <- torch_tensor(input)$to(torch_float())
    },
    .getitem = function(index) {
        self$data[index,]
    },
    .length = function() {
        self$data$size()[[1]]
    }
)

architecture <- nn_module(
    "mlp",
    initialize = function() {
        self$model <- nn_sequential(
            nn_linear(19, 3),
            nn_relu(),
            nn_linear(3, 1),
            nn_sigmoid())
    },
    forward = function(x) {
        self$model(x[,1:19])
    }
)

model <- architecture()

nb <- 10

dl <- dataloader(messidor_dataset(), batch_size = nb, shuffle = TRUE)

opt <- optim_adam(model$parameters, lr = 0.001)

lf <- nn_bce_loss()

for (epoch in 1:100) {
    i <- 0
    l <- 0

    coro::loop(for (b in dl) {
                   opt$zero_grad()
                   y <- model(b)
                   loss <- lf(y, b[,20])
                   i <- i + 1
                   l <- l + loss
                   loss$backward()
                   opt$step()
               })

    cat(sprintf("loss at epoch %d: %f\n", epoch, l/i))
}
