#include <stdio.h>
#include <stdlib.h>
#include <curand_kernel.h>
#include <time.h>

#define X 1
#define O -1
#define BLANK 0

#define NUM_THREAD 500
#define RUNS_PER_THREAD 20
#define NUM_BLOCKS 20
#define NUM_SEQ_LOOPS 200000

//When a subBoard is won, it should be filled with that mark. (All X or all O) This is needed as a speed optimization

__device__ __host__ void printSquare(int x){
    switch(x)
    {
        case X:
            printf("X");
            break;
        case O:
            printf("O");
            break;
        case BLANK:
            printf("_");
            break;
    }
}

bool printSquareWithNumber(int x, int num){
    switch(x)
    {
        case X:
            printf("XX");
            return false;
        case O:
            printf("OO");
            return false;
        case BLANK:
            printf("%d", num);
            if(num<=9) { printf(" ");}
            return true;
    }
    return false;
}

void PrintBoardWithNumbers(int* board){
    int x,y,j,i, num;
    num = 0;
    for(x = 0; x <3; x++)
    {
        printf("_____________\n");
        for(i = 0; i < 3; i++)
        {
            printf("|");
            for(y = 0; y < 3; y++)
            {
                for(j = 0; j< 3; j++)
                {
                    if(printSquareWithNumber(board[(3*x+y)*9+(3*i+j)],num))
                    {
                        num++;
                    }
                }
                printf("|");
            }
            printf("\n");
        }
    }
    printf("_____________\n");
}

void PrintBoard(int* board){
    int x,y,j,i;
    for(x = 0; x <3; x++)
    {
        printf("_____________\n");
        for(i = 0; i < 3; i++)
        {
            printf("|");
            for(y = 0; y < 3; y++)
            {
                for(j = 0; j< 3; j++)
                {
                    printSquare(board[(3*x+y)*9+(3*i+j)]);
                }
                printf("|");
            }
            printf("\n");
        }
    }
    printf("_____________\n");
}

void PrintSubBoardWithNumbers(int* subBoard){
    int x,y, num;
    num = 0;
    for(x = 0; x < 3; x++)
    {
        printf("|");
        for(y = 0; y < 3; y++)
        {
            if(printSquareWithNumber(subBoard[3*x+y],num))
            {
                num++;
            }
        }
        printf("|\n");
    }
}

void PrintSubBoard(int* subBoard){
    int x,y;
    for(x = 0; x < 3; x++)
    {
        printf("|");
        for(y = 0; y < 3; y++)
        {
            printSquare(subBoard[3*x+y]);
        }
        printf("|\n");
    }
}

__device__ __host__ int SubBoardWinner(int* subBoard){
    int i, total;
    //left to right wins
    for(i = 0; i < 3; i++)
    {
        total = subBoard[3*i] + subBoard[3*i +1 ] + subBoard[3*i+2];
       // printf("total: %d\n",total);
        if(abs(total) == 3)
        {
            return (total/3);
        }
    }
    //up to down
    for(i = 0; i < 3; i++)
    {
        total = subBoard[i] + subBoard[3+i] + subBoard[6+i];
       // printf("total: %d\n",total);
        if(abs(total) == 3)
        {
            return (total/3);
        }
    }
    //Diagonals
    total = subBoard[0] + subBoard[4] + subBoard[8];
    //printf("total: %d\n",total);
    if(abs(total) == 3)
    {
        return (total/3);
    }
    total = subBoard[2] + subBoard[4] + subBoard[6];
   // printf("total: %d\n",total);
    if(abs(total) == 3)
    {
        return (total/3);
    }
    return 0;
}

int SubBoardWinner(double* subBoard){
    int i, total;
    //left to right wins
    for(i = 0; i < 3; i++)
    {
        total = subBoard[3*i] + subBoard[3*i +1 ] + subBoard[3*i+2];
        if(abs(total) == 3)
        {
            return (total/3);
        }
    }
    //up to down
    for(i = 0; i < 3; i++)
    {
        total = subBoard[i] + subBoard[  3+i ] + subBoard[6+i];
        if(abs(total) == 3)
        {
            return (total/3);
        }
    }
    //Diagonals
    total = subBoard[0] + subBoard[4] + subBoard[8];
    if(abs(total) == 3)
    {
        return (total/3);
    }
    total = subBoard[2] + subBoard[4] + subBoard[6];
    if(abs(total) == 3)
    {
        return (total/3);
    }
    return 0;
}

__device__ __host__ int BoardWinner(int* board){
    int i,metaBoard[9];
    for(i = 0; i < 9; i++)
    {
        metaBoard[i] = SubBoardWinner(board+(i*9));
    }
    return SubBoardWinner(metaBoard);
}

__device__ __host__ bool IsSubBoardFull(int* subBoard){
    int i;
    for(i = 0; i < 9; i++)
    {
        if(subBoard[i] == 0)
        {
            return false;
        }
    }
    return true;
}

__device__ __host__ bool IsSubBoardFull(double* subBoard){
    int i;
    for(i = 0; i < 9; i++)
    {
        if(subBoard[i] != 1 || subBoard[i] != -1)
        {
            return false;
        }
    }
    return true;
}

__device__ __host__ bool IsBoardFull(int* board){
    for(int i = 0; i < 81; i++)
    {
        if(board[i] == BLANK)
        {
            return false;
        }
    }
    return true;
}

__device__ __host__ int NumberOfFreeSquaresInFullBoard(int* board){
    int i, count = 0;
    for(i = 0; i < 81; i++)
    {
        if(board[i] == 0)
        {
            count++;
        }
    }
    return count;
}

__device__ __host__ int NumberOfFreeSquaresInSubBoard(int* subBoard){
    int i, count = 0;
    for(i = 0; i < 9; i++)
    {
        if(subBoard[i] == 0)
        {
            count++;
        }
    }
    return count;
}

__device__ __host__ int NumberOfPossibleMoves(int* board, int lastMove, bool fullBoard){
    int subBoard = lastMove % 9;
    if(fullBoard)
    {
        return NumberOfFreeSquaresInFullBoard(board);
    }
    else
    {
        return NumberOfFreeSquaresInSubBoard(board + 9*subBoard);
    }
}

int DoEvalRow(int a, int b, int c){
    int count = 0;
    int sum = a + b + c;
    if(a != 0) {count++;}
    if(b != 0) {count++;}
    if(c != 0) {count++;}
    return sum * count;
}

double DoEvalRow(double a, double b, double c){
    int count = 0;
    double sum = a + b + c;
    if(sum > 0)
    {
        if(a > 0) {count++;}
        if(b > 0) {count++;}
        if(c > 0) {count++;}
    }
    else
    {
        if(a < 0) {count++;}
        if(b < 0) {count++;}
        if(c < 0) {count++;}
    }
    return sum * (double)count;
}

int EvalRow(int a, int b, int c){
    if( a >= 0 && b >= 0  && c >= 0)
    {
        return DoEvalRow(a,b,c);
    }
    else if( a <= 0 && b <= 0 && c <= 0)
    {
        return DoEvalRow(a,b,c);
    }
    else
    {
        return 0;
    }
}

double EvalSubBoard(int* subBoard){
    double sum = 0;
    int winner = SubBoardWinner(subBoard);
    switch (winner)
    {
        case BLANK:
            if(IsSubBoardFull(subBoard))
            {
                return 0;
            }
            sum += EvalRow(subBoard[0],subBoard[1],subBoard[2]);
            sum += EvalRow(subBoard[3],subBoard[4],subBoard[5]);
            sum += EvalRow(subBoard[6],subBoard[7],subBoard[8]);
            sum += EvalRow(subBoard[0],subBoard[3],subBoard[6]);
            sum += EvalRow(subBoard[1],subBoard[4],subBoard[7]);
            sum += EvalRow(subBoard[2],subBoard[5],subBoard[8]);
            sum += EvalRow(subBoard[0],subBoard[4],subBoard[8]);
            sum += EvalRow(subBoard[2],subBoard[4],subBoard[6]);
            sum /= 21;
            break;
        case  X:
            sum = 1;
            break;
        case O:
            sum = -1;
            break;
    }
    return sum;
}

double EvalMetaRow(double a, double b, double c){
    if( a > -1 && b > -1  && c > -1)
    {
        return DoEvalRow(a,b,c);
    }
    else if( a < 1 && b < 1 && c < 1)
    {
        return DoEvalRow(a,b,c);
    }
    else
    {
        return 0;
    }
}

double EvalMetaBoard(double* subBoard){
    double sum = 0;
    int winner = SubBoardWinner(subBoard);
    switch (winner)
    {
        case BLANK:
            if(IsSubBoardFull(subBoard))
            {
                return 0;
            }
            sum += EvalMetaRow(subBoard[0],subBoard[1],subBoard[2]);
            sum += EvalMetaRow(subBoard[3],subBoard[4],subBoard[5]);
            sum += EvalMetaRow(subBoard[6],subBoard[7],subBoard[8]);
            sum += EvalMetaRow(subBoard[0],subBoard[3],subBoard[6]);
            sum += EvalMetaRow(subBoard[1],subBoard[4],subBoard[7]);
            sum += EvalMetaRow(subBoard[2],subBoard[5],subBoard[8]);
            sum += EvalMetaRow(subBoard[0],subBoard[4],subBoard[8]);
            sum += EvalMetaRow(subBoard[2],subBoard[4],subBoard[6]);
            break;
        case  X:
            sum = 21;
            break;
        case O:
            sum = -21;
            break;
    }
    return sum;
}

double EvalFullBoard(int* board){
    int i;
    double metaBoard[9];
    int winner = BoardWinner(board);
    switch(winner)
    {
        case BLANK:
            if(IsBoardFull(board))
            {
                return 0;
            }
            for(i = 0; i < 9; i++)
            {
                metaBoard[i] = EvalSubBoard(board + 9*i);
            }
            return EvalMetaBoard(metaBoard);
        case X:
            return (double)21;
        case O:
            return (double)-21;
    }
    return 98;
}

__device__ int EvalFullBoardKenel(int* board){
    switch(BoardWinner(board))
    {
        case X:
            return 1;
        case O:
            return -1;
        case BLANK:
            return 0;
    }
    return 0;
}

__device__ __host__ int PlaceMoveinSubBoard(int* board, int lastMove, int placement, int mark){
    int subBoard, freeSquares, i;
    subBoard = lastMove % 9;
    freeSquares = 0;
    for(i = 0; i < 9; i++)
    {
        if(board[subBoard* 9 + i] == 0)
        {
            if(freeSquares == placement)
            {
                board[subBoard* 9 + i] = mark;
                freeSquares = i;
                break;
            }
            freeSquares++;
        }
    }
    if( SubBoardWinner(board + subBoard * 9 ) != 0 )
    {
        for(i = 0; i < 9; i++)
        {
            board[subBoard* 9 + i] = mark;
        }
    }
    return subBoard * 9 + freeSquares;
}

__device__ __host__ int PlaceMarkinNthFree(int* board, int lastMove, int placement, int mark){
    int subBoard, freeSquares, i;
    freeSquares = 0;
    for(i = 0; i < 81; i++)
    {
        if(board[i] == 0)
        {

            if(freeSquares == placement)
            {
                board[i] = mark;
                freeSquares = i;
                break;
            }
            freeSquares++;
        }
    }
    subBoard = i / 9;
    if( SubBoardWinner(board + subBoard * 9 ) != 0 )
    {
        for(i = 0; i < 9; i++)
        {
            board[subBoard* 9 + i] = mark;
        }
    }
    return subBoard * 9 + freeSquares;
}

int playRandomMove(int* board, int lastMove, int mark){

    int subBoard = lastMove%9;
    bool fullBoard = SubBoardWinner(board+9*subBoard) != 0 || IsSubBoardFull(board+subBoard*9) ;
    int numOfMoves = NumberOfPossibleMoves(board, lastMove, fullBoard);
    int index = rand() % (numOfMoves);
    if(fullBoard)
    {
        return PlaceMarkinNthFree(board, lastMove, index, mark);
    }
    else
    {
       return PlaceMoveinSubBoard(board, lastMove, index, mark);
    }
}

__device__ int playRandomMove(int* board, int lastMove, int mark, curandState_t  state){

    int subBoard = lastMove%9;
    bool fullBoard = SubBoardWinner(board+9*subBoard) != 0 || IsSubBoardFull(board+subBoard*9) ;
    int numOfMoves = NumberOfPossibleMoves(board, lastMove, fullBoard);
    int index = curand(&state) % (numOfMoves);
    if(fullBoard)
    {
        return PlaceMarkinNthFree(board, lastMove, index, mark);
    }
    else
    {
       return PlaceMoveinSubBoard(board, lastMove, index, mark);
    }
}


int MonteCarlo(int* board, int lastMove, int mark, int numRuns){

    int fakeBoard[81];
    int fakeLastMove;
    int fakeMark;
    int subBoard = lastMove%9;
    bool fullBoard = SubBoardWinner(board+9*subBoard) != 0 || IsSubBoardFull(board+subBoard*9) ;
    int numOfMoves = NumberOfPossibleMoves(board, lastMove, fullBoard);
    double score [70];
    for(int i = 0; i < 70; i++)
    {
        score[i] = 0;
    }
    for(int i = 0; i < numRuns; i++)
    {
        for(int j = 0; j < 81; j++)
        {

            fakeBoard[j] = board[j];
              fakeLastMove = lastMove;
          }
        int index = i % (numOfMoves);
        fakeMark = mark;
        if(BoardWinner(fakeBoard) == 0 && !IsBoardFull(fakeBoard)){
            if(fullBoard)
            {
                fakeLastMove = PlaceMarkinNthFree(fakeBoard, fakeLastMove, index, fakeMark);
            }
            else
            {
               fakeLastMove = PlaceMoveinSubBoard(fakeBoard, fakeLastMove, index, fakeMark);
            }
            fakeMark = fakeMark * -1;
            while(BoardWinner(fakeBoard) == 0 && !IsBoardFull(fakeBoard))
            {
                fakeLastMove = playRandomMove(fakeBoard, fakeLastMove, fakeMark);
                fakeMark = -1 * fakeMark;
            }
        }
        score[i % numOfMoves] = EvalFullBoard(fakeBoard) + score[i % numOfMoves];
    }
    int winningIndex = 0;
    if(mark == X)
    {
        double max = score[0];
        for(int i = 0; i < numOfMoves; i++)
        {
            if(score[i] > max)
            {
                winningIndex = i;
                max = score[i];
            }
        }
    }
    else
    {
        double min = score[0];
        for(int i = 0; i < numOfMoves; i++)
        {
            if(score[i] < min)
            {
                winningIndex = i;
                min = score[i];


            }
        }
    }

    if(fullBoard)
    {
        return PlaceMarkinNthFree(board, lastMove, winningIndex, mark);
    }
    else
    {
       return PlaceMoveinSubBoard(board, lastMove, winningIndex, mark);
    }
}

__global__ void MonteCarloKernel(int* board, int* lastMove, int* mark, bool* fullBoard, int* numOfMoves, int* score, int Runs){
    extern  __shared__ int shared[];
    int tId = threadIdx.x + (blockIdx.x * blockDim.x);
    int thread = threadIdx.x;
    curandState_t  state;
    curand_init((unsigned long long)clock() + tId, 0, 0, &state);
    int o_board[81];
    int fakeBoard[81];
    int fakeLastMove;
    int fakeMark;
    if(thread < *numOfMoves)
    {
        shared[thread] = 0;
    }
    for(int j = 0; j < 81; j++)
    {
        o_board[j] = board[j];
    }
    __syncthreads();
    //offset by tID to reduce collisions on the scores
    for(int i = 0+tId; i < Runs +tId; i++)
    {
        //reset the board in local mem
        for(int j = 0; j < 81; j++)
        {
            fakeBoard[j] = o_board[j];
        }
        int index = i % (*numOfMoves);
        fakeMark = *mark;
        fakeLastMove = *lastMove;
        if(BoardWinner(fakeBoard) == 0 && !IsBoardFull(fakeBoard)){
            if(*fullBoard)
            {
                fakeLastMove = PlaceMarkinNthFree(fakeBoard, fakeLastMove, index, fakeMark);
            }
            else
            {
               fakeLastMove = PlaceMoveinSubBoard(fakeBoard, fakeLastMove, index, fakeMark);
            }
            fakeMark = fakeMark * -1;
            while(BoardWinner(fakeBoard) == 0 && !IsBoardFull(fakeBoard))
            {
                fakeLastMove = playRandomMove(fakeBoard, fakeLastMove, fakeMark, state);
                fakeMark = -1 * fakeMark;
            }
        }
        atomicAdd(&shared[i%(*numOfMoves)], EvalFullBoardKenel(fakeBoard));
    }
    __syncthreads();
    if(thread < *numOfMoves)
    {
        atomicAdd(&score[thread], shared[thread]);
    }
}


int ParMonteCarlo(int* board, int lastMove, int mark, int Runs)
{
    int *d_board, *d_score ,*d_numOfMoves, *d_mark, *d_lastMove;
    bool *d_fullBoard;
    int score[70];
    memset(score, 0, sizeof(int) * 70);
    int subBoard = lastMove%9;
    bool fullBoard = SubBoardWinner(board+9*subBoard) != 0 || IsSubBoardFull(board+subBoard*9);
    int numOfMoves = NumberOfPossibleMoves(board, lastMove, fullBoard);
    cudaMalloc(&d_board, sizeof(int) * 81);
    cudaMalloc(&d_score, sizeof(int) * 70);
    cudaMalloc(&d_mark ,sizeof(int));
    cudaMalloc(&d_lastMove ,sizeof(int));
    cudaMalloc(&d_numOfMoves ,sizeof(int));
    cudaMalloc(&d_fullBoard ,sizeof(bool));
    cudaMemset(d_score, 0, sizeof(int) * 70);
    cudaMemcpy(d_board, board, sizeof(int) *81, cudaMemcpyHostToDevice);
    cudaMemcpy(d_mark,&mark,sizeof(int),cudaMemcpyHostToDevice);
    cudaMemcpy(d_numOfMoves,&numOfMoves,sizeof(int),cudaMemcpyHostToDevice);
    cudaMemcpy(d_lastMove,&lastMove,sizeof(int),cudaMemcpyHostToDevice);
    cudaMemcpy(d_fullBoard,&fullBoard,sizeof(bool),cudaMemcpyHostToDevice);
    MonteCarloKernel<<<NUM_BLOCKS,NUM_THREAD, sizeof(int) * 70>>>(d_board, d_lastMove, d_mark, d_fullBoard, d_numOfMoves, d_score, Runs);
    cudaDeviceSynchronize();
    cudaMemcpy(score, d_score, sizeof(int)*70, cudaMemcpyDeviceToHost);
    int winningIndex = 0;
    if(mark == X)
    {
        double max = score[0];
        for(int i = 0; i < 70; i++)
        {
            if(score[i] > max)
            {
                winningIndex = i;
                max = score[i];
            }
        }
    }
    else
    {
        double min = score[0];
        for(int i = 0; i < 70; i++)
        {
            if(score[i] < min)
            {
                winningIndex = i;
                min = score[i];
            }
        }
    }
    cudaFree(d_board);
    cudaFree(d_score);
    cudaFree(d_mark);
    cudaFree(d_numOfMoves);
    cudaFree(d_lastMove);
    cudaFree(d_fullBoard);
    if(fullBoard)
    {
        return PlaceMarkinNthFree(board, lastMove, winningIndex, mark);
    }
    else
    {
       return PlaceMoveinSubBoard(board, lastMove, winningIndex, mark);
    }
}


int main()
{
    clock_t start;
    clock_t diff;
    clock_t end;
    clock_t ParTime = 0;
    clock_t SeqTime = 0;
    int Xwin = 0;
    int Ywin = 0;
    srand(time(NULL));
    for(int i = 0; i < 10; i++)
    {
        ParTime = 0;
        SeqTime = 0;
        int board[81];
        memset(board, BLANK, sizeof(int)*81);
        int lastMove = 0;
        int mark = 1;
        bool test= true;
        while(BoardWinner(board) == 0 && !IsBoardFull(board) )
        {
            if(test)
            {
                printf("Monte Carlo Turn in Parallel\n");
                start = clock();
                lastMove = ParMonteCarlo(board, lastMove, mark, RUNS_PER_THREAD);
                end = clock();
                diff =end -start;
                ParTime += diff;

                printf("Par Time: %d\n", diff);
            }
            else
            {
                printf("Monte Carlo Turn in Sequence\n");
                start = clock();
                lastMove = MonteCarlo(board, lastMove, mark, NUM_SEQ_LOOPS);
                end = clock();
                diff = end-start;
                SeqTime += diff;
                printf("Seq Time: %d\n", diff);
            }
            mark = mark * -1;
            test = !test;
            PrintBoard(board);

        }
        if(BoardWinner(board) == X)
        {
            Xwin++;
        }
        else if (BoardWinner(board)== O)
        {
            Ywin++;
        }
        printf("Parallel Time Total %d, Seq Time Total: %d\n",ParTime, SeqTime );
        printf("BoardWinner: ");
        printSquare(BoardWinner(board));
        printf("\n");
    }
    printf("X won %d times\n out of 10\n",Xwin);
    printf("O won %d times\n out of 10\n",Ywin);
    return 0;

}
