module umdc;

import std.math;
import std.stdio;
import std.container.array;
import std.typecons;
import std.conv;
import core.stdc.string;
import std.datetime.stopwatch;
import std.parallelism;
import std.range;

import math;
import matrix;
import util;
import traits;
import bindings;
import render;
import hermite;



//function that prints special table
/*void printSpecialTable1(){
    string str = "[";

    foreach(i;0..256){
        str ~= "\n[";
        int[16] entries = edgeTable[i];

        size_t s = 0;

        bool[3] set;
        set[0] = false;
        set[1] = false;
        set[2] = false;

        foreach(j;0..16){
            if(entries[j] == -2){
                if(set[0]){
                    str ~= "0, ";
                }
                if(set[1]){
                    str ~= "3, ";
                }
                if(set[2]){
                    if(s == 3)
                        str ~= "8";
                    else
                        str ~= "8, ";
                }
                while(s < 2){
                    str ~= "-2, ";
                    s++;
                }
                if(s == 2){
                    str ~= "-2";
                }
                str ~= "],";
                break;
            }else if(entries[j] == 0){
                s += 1;
                set[0] = true;
            }else if(entries[j] == 3){
                 s += 1;
                 set[1] = true;
            }else if(entries[j] == 8){
                 s += 1;
                 set[2] = true;
            }
        }
    }

    writeln( str ~ "\n]" );
}*/



//in D static rectangular array is continious in memory
//TODO move this table + edgePairs to hermite.uniform ?
int[16][256] edgeTable = [
                                   [-2, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1],
                                   [0, 8, 3, -2, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1],
                                   [0, 1, 9, -2, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1],
                                   [1, 3, 8, 9, -2, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1],
                                   [1, 2, 10, -2, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1],
                                   [0, 8, 3, -1, 1, 2, 10, -2, -1, -1, -1, -1, -1, -1, -1, -1],
                                   [9, 0, 2, 10, -2, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1],
                                   [10, 2, 3, 8, 9, -2, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1],
                                   [3, 11, 2, -2, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1],
                                   [0, 8, 11, 2, -2, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1],
                                   [1, 9, 0, -1, 2, 3, 11, -2, -1, -1, -1, -1, -1, -1, -1, -1],
                                   [1, 2, 8, 9, 11, -2, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1],
                                   [1, 3, 10, 11, -2, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1],
                                   [0, 1, 8, 10, 11, -2, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1],
                                   [0, 3, 9, 10, 11, -2, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1],
                                   [8, 9, 10, 11, -2, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1],
                                   [4, 7, 8, -2, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1],
                                   [0, 3, 4, 7, -2, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1],
                                   [0, 1, 9, -1, 8, 4, 7, -2, -1, -1, -1, -1, -1, -1, -1, -1],
                                   [1, 3, 4, 7, 9, -2, -1, -1, 1, -1, -1, -1, -1, -1, -1, -1],
                                   [1, 2, 10, -1, 8, 4, 7, -2, -1, -1, -1, -1, -1, -1, -1, -1],
                                   [1, 2, 10, -1, 0, 3, 7, 4, -2, -1, -1, -1, -1, -1, -1, -1],
                                   [0, 2, 10, 9, -1, 8, 7, 4, -2, -1, -1, -1, -1, -1, -1, -1],
                                   [2, 3, 4, 7, 9, 10, -2, -1, -1, -1, -1, -1, -1, -1, -1, -1],
                                   [8, 4, 7, -1, 3, 11, 2, -2, -1, -1, -1, -1, -1, -1, -1, -1],
                                   [0, 2, 4, 7, 11, -2, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1],
                                   [9, 0, 1, -1, 8, 4, 7, -1, 2, 3, 11, -2, -1, -1, -1, -1],
                                   [1, 2, 4, 7, 9, 11, -2, -1, -1, -1, -1, -1-1, -1, -1, -1, -1],
                                   [3, 11, 10, 1, -1, 8, 7, 4, -2, -1, -1, -1, -1, -1, -1, -1],
                                   [0, 1, 4, 7, 10, 11, -2, -1, -1, -1, -1, -1, -1, -1, -1, -1],
                                   [4, 7, 8, -1, 0, 3, 11, 10, 9, -2, -1, -1, -1, -1, -1, -1],
                                   [4, 7, 9, 10, 11, -2, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1],
                                   [9, 5, 4, -2, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1],
                                   [9, 5, 4, -1, 0, 8, 3, -2, -1, -1, -1, -1, -1, -1, -1, -1],
                                   [0, 5, 4, 1, -2, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1],
                                   [1, 3, 4, 5, 8, -2, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1],
                                   [1, 2, 10, -1, 9, 5, 4, -2, -1, -1, -1, -1, -1, -1, -1, -1],
                                   [3, 0, 8, -1, 1, 2, 10, -1, 4, 9, 5, -2, -1, -1, -1, -1],
                                   [0, 2, 4, 5, 10, -2, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1],
                                   [2, 3, 4, 5, 8, 10, -2, -1, -1, -1, -1, -1, -1, -1, -1, -1],
                                   [9, 5, 4, -1, 2, 3, 11, -2, -1, -1, -1, -1, -1, -1, -1, -1],
                                   [9, 4, 5, -1, 0, 2, 11, 8, -2, -1, -1, -1, -1, -1, -1, -1],
                                   [3, 11, 2, -1, 0, 4, 5, 1, -2, -1, -1, -1, -1, -1, -1, -1],
                                   [1, 2, 4, 5, 8, 11, -2, -1, -1, -1, -1, -1, -1, -1, -1, -1],
                                   [3, 11, 10, 1, -1, 9, 4, 5, -2, -1, -1, -1, -1, -1, -1, -1],
                                   [4, 9, 5, -1, 0, 1, 8, 10, 11, -2, -1, -1, -1, -1, -1, -1],
                                   [0, 3, 4, 5, 10, 11, -2, -1, -1, -1, -1, -1, -1, -1, -1, -1],
                                   [5, 4, 8, 10, 11, -2, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1],
                                   [5, 7, 8, 9, -2, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1],
                                   [0, 3, 5, 7, 9, -2, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1],
                                   [0, 1, 5, 7, 8, -2, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1],
                                   [1, 5, 3, 7, -2, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1],
                                   [1, 2, 10, -1, 8, 7, 5, 9, -2, -1, -1, -1, -1, -1, -1, -1],
                                   [1, 2, 10, -1, 0, 3, 7, 5, 9, -2, -1, -1, -1, -1, -1, -1],
                                   [0, 2, 5, 7, 8, 10, -2, -1, -1, -1, -1, -1, -1, -1, -1, -1],
                                   [2, 3, 5, 7, 10, -2, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1],
                                   [2, 3, 11, -1, 5, 7, 8, 9, -2, -1, -1, -1, -1, -1, -1, -1],
                                   [0, 2, 5, 7, 9, 11, -2, -1, -1, -1, -1, -1, -1, -1, -1, -1],
                                   [2, 3, 11, -1, 0, 1, 5, 7, 8, -2, -1, -1, -1, -1, -1, -1],
                                   [1, 2, 5, 7, 11, -2, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1],
                                   [3, 11, 10, 1, -1, 8, 7, 5, 9, -2, -1, -1, -1, -1, -1, -1],
                                   [0, 1, 5, 7, 9, 10, 11, -2, -1, -1, -1, -1, -1, -1, -1, -1],
                                   [0, 3, 5, 7, 8, 10, 11, -2, -1, -1, -1, -1, -1, -1, -1, -1],
                                   [5, 7, 10, 11, -2, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1],
                                   [5, 6, 10, -2, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1],
                                   [0, 3, 8, -1, 10, 5, 6, -2, -1, -1, -1, -1, -1, -1, -1, -1],
                                   [0, 1, 9, -1, 10, 5, 6, -2, -1, -1, -1, -1, -1, -1, -1, -1],
                                   [10, 5, 6, -1, 3, 8, 9, 1, -2, -1, -1, -1, -1, -1, -1, -1],
                                   [1, 2, 5, 6, -2, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1],
                                   [0, 3, 8, -1, 1, 2, 6, 5, -2, -1, -1, -1, -1, -1, -1, -1],
                                   [0, 2, 5, 6, 9, -2, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1],
                                   [2, 3, 5, 6, 8, 9, -2, -1, -1, -1, -1, -1, -1, -1, -1, -1],
                                   [3, 11, 2, -1, 10, 6, 5, -2, -1, -1, -1, -1, -1, -1, -1, -1],
                                   [10, 5, 6, -1, 0, 8, 2, 11, -2, -1, -1, -1, -1, -1, -1, -1],
                                   [3, 11, 2, -1, 0, 1, 9, -1, 10, 5, 6, -2, -1, -1, -1, -1],
                                   [10, 5, 6, -1, 11, 2, 8, 9, 1, -2, -1, -1, -1, -1, -1, -1],
                                   [1, 3, 5, 6, 11, -2, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1],
                                   [0, 1, 5, 6, 8, 11, -2, -1, -1, -1, -1, -1, -1, -1, -1, -1],
                                   [0, 3, 5, 6, 9, 11, -2, -1, -1, -1, -1, -1, -1, -1, -1, -1],
                                   [5, 6, 8, 9, 11, -2, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1],
                                   [8, 7, 4, -1, 5, 6, 10, -2, -1, -1, -1, -1, -1, -1, -1, -1],
                                   [5, 6, 10, -1, 0, 3, 4, 7, -2, -1, -1, -1, -1, -1, -1, -1],
                                   [10, 5, 6, -1, 1, 9, 0, -1, 8, 7, 4, -2, -1, -1, -1, -1],
                                   [10, 5, 6, -1, 7, 4, 9, 1, 3, -2, -1, -1, -1, -1, -1, -1],
                                   [8, 7, 4, -1, 1, 2, 6, 5, -2, -1, -1, -1, -1, -1, -1, -1],
                                   [0, 3, 7, 4, -1, 1, 2, 6, 5, -2, -1, -1, -1, -1, -1, -1],
                                   [8, 7, 4, -1, 0, 9, 2, 5, 6, -2, -1, -1, -1, -1, -1, -1],
                                   [2, 3, 4, 5, 6, 7, 9, -2, -1, -1, -1, -1, -1, -1, -1, -1],
                                   [3, 11, 2, -1, 5, 6, 10, -1, 8, 7, 4, -2, -1, -1, -1, -1],
                                   [10, 5, 6, -1, 0, 2, 11, 7, 4, -2, -1, -1, -1, -1, -1, -1],
                                   [3, 11, 2, -1, 0, 1, 9, -1, 10, 5, 6, -1, 8, 7, 4, -2],
                                   [10, 5, 6, -1, 7, 4, 11, 2, 1, 9, -2, -1, -1, -1, -1, -1],
                                   [8, 7, 4, -1, 3, 11, 6, 5, 1, -2, -1, -1, -1, -1, -1, -1],
                                   [0, 1, 4, 5, 6, 7, 11, -2, -1, -1, -1, -1, -1, -1, -1, -1],
                                   [8, 7, 4, -1, 6, 5, 9, 0, 11, 3, -2, -1, -1, -1, -1, -1],
                                   [4, 5, 6, 7, 9, 11, -2, -1, -1, -1, -1, -1, -1, -1, -1, -1],
                                   [4, 6, 9, 10, -2, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1],
                                   [0, 3, 8, -1, 9, 10, 6, 4, -2, -1, -1, -1, -1, -1, -1, -1],
                                   [0, 1, 4, 6, 10, -2, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1],
                                   [1, 3, 4, 6, 8, 10, -2, -1, -1, -1, -1, -1, -1, -1, -1, -1],
                                   [1, 2, 4, 6, 9, -2, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1],
                                   [0, 3, 8, -1, 1, 2, 4, 6, 9, -2, -1, -1, -1, -1, -1, -1],
                                   [0, 2, 4, 6, -2, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1],
                                   [2, 3, 4, 6, 8, -2, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1],
                                   [11, 2, 3, -1, 9, 4, 10, 6, -2, -1, -1, -1, -1, -1, -1, -1],
                                   [0, 2, 11, 8, -1, 9, 4, 6, 10, -2, -1, -1, -1, -1, -1, -1],
                                   [2, 3, 11, -1, 0, 1, 4, 6, 10, -2, -1, -1, -1, -1, -1, -1],
                                   [1, 2, 4, 6, 8, 10, 11, -2, -1, -1, -1, -1, -1, -1, -1, -1],
                                   [1, 3, 4, 6, 9, 11, -2, -1, -1, -1, -1, -1, -1, -1, -1, -1],
                                   [0, 1, 4, 6, 8, 9, 11, -2, -1, -1, -1, -1, -1, -1, -1, -1],
                                   [0, 3, 4, 6, 11, -2, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1],
                                   [4, 6, 8, 11, -2, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1],
                                   [6, 7, 8, 9, 10, -2, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1],
                                   [0, 3, 6, 7, 9, 10, -2, -1, -1, -1, -1, -1, -1, -1, -1, -1],
                                   [0, 1, 6, 7, 8, 10, -2, -1, -1, -1, -1, -1, -1, -1, -1, -1],
                                   [1, 3, 6, 7, 10, -2, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1],
                                   [1, 2, 6, 7, 8, 9, -2, -1, -1, -1, -1, -1, -1, -1, -1, -1],
                                   [0, 1, 2, 3, 6, 7, 9, -2, -1, -1, -1, -1, -1, -1, -1, -1],
                                   [0, 2, 6, 7, 8, -2, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1],
                                   [2, 3, 6, 7, -2, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1],
                                   [3, 11, 2, -1, 10, 6, 9, 7, 8, -2, -1, -1, -1, -1, -1, -1],
                                   [0, 2, 6, 7, 9, 10, 11, -2, -1, -1, -1, -1, -1, -1, -1, -1],
                                   [3, 11, 2, -1, 8, 7, 0, 1, 10, 6, -2, -1, -1, -1, -1, -1],
                                   [1, 2, 6, 7, 10, 11, -2, -1, -1, -1, -1, -1, -1, -1, -1, -1],
                                   [1, 3, 6, 7, 8, 9, 11, -2, -1, -1, -1, -1, -1, -1, -1, -1],
                                   [0, 1, 6, 7, 9, 11, -2, -1, -1, -1, -1, -1, -1, -1, -1, -1],
                                   [0, 3, 6, 7, 8, 11, -2, -1, -1, -1, -1, -1, -1, -1, -1, -1],
                                   [6, 7, 11, -2, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1],
                                   [11, 7, 6, -2, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1],
                                   [11, 7, 6, -1, 0, 3, 8, -2, -1, -1, -1, -1, -1, -1, -1, -1],
                                   [11, 7, 6, -1, 0, 9, 1, -2, -1, -1, -1, -1, -1, -1, -1, -1],
                                   [11, 7, 6, -1, 1, 3, 8, 9, -2, -1, -1, -1, -1, -1, -1, -1],
                                   [11, 7, 6, -1, 1, 2, 10, -2, -1, -1, -1, -1, -1, -1, -1, -1],
                                   [11, 7, 6, -1, 1, 2, 10, -1, 0, 3, 8, -2, -1, -1, -1, -1],
                                   [11, 7, 6, -1, 0, 9, 10, 2, -2, -1, -1, -1, -1, -1, -1, -1],
                                   [11, 7, 6, -1, 2, 3, 8, 9, 10, -2, -1, -1, -1, -1, -1, -1],
                                   [2, 3, 6, 7, -2, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1],
                                   [0, 2, 6, 7, 8, -2, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1],
                                   [0, 1, 9, -1, 3, 2, 6, 7, -2, -1, -1, -1, -1, -1, -1, -1],
                                   [1, 2, 6, 7, 8, 9, -2, -1, -1, -1, -1, -1, -1, -1, -1, -1],
                                   [1, 3, 6, 7, 10, -2, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1],
                                   [0, 1, 6, 7, 8, 10, -2, -1, -1, -1, -1, -1, -1, -1, -1, -1],
                                   [0, 3, 6, 7, 9, 10, -2, -1, -1, -1, -1, -1, -1, -1, -1, -1],
                                   [6, 7, 8, 9, 10, -2, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1],
                                   [4, 6, 8, 11, -2, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1],
                                   [0, 3, 4, 6, 11, -2, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1],
                                   [0, 1, 9, -1, 8, 4, 11, 6, -2, -1, -1, -1, -1, -1, -1, -1],
                                   [1, 3, 4, 6, 9, 11, -2, -1, -1, -1, -1, -1, -1, -1, -1, -1],
                                   [1, 2, 10, -1, 8, 4, 6, 11, -2, -1, -1, -1, -1, -1, -1, -1],
                                   [1, 2, 10, -1, 0, 3, 11, 6, 4, -2, -1, -1, -1, -1, -1, -1],
                                   [0, 9, 10, 2, -1, 8, 4, 11, 6, -2, -1, -1, -1, -1, -1, -1],
                                   [2, 3, 4, 6, 9, 10, 11, -2, -1, -1, -1, -1, -1, -1, -1, -1],
                                   [2, 3, 4, 6, 8, -2, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1],
                                   [0, 2, 4, 6, -2, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1],
                                   [0, 1, 9, -1, 2, 3, 8, 4, 6, -2, -1, -1, -1, -1, -1, -1],
                                   [1, 2, 4, 6, 9, -2, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1],
                                   [1, 3, 4, 6, 8, 10, -2, -1, -1, -1, -1, -1, -1, -1, -1, -1],
                                   [0, 1, 4, 6, 10, -2, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1],
                                   [0, 3, 4, 6, 8, 9, 10, -2, -1, -1, -1, -1, -1, -1, -1, -1],
                                   [4, 6, 9, 10, -2, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1],
                                   [6, 7, 11, -1, 4, 5, 9, -2, -1, -1, -1, -1, -1, -1, -1, -1],
                                   [6, 7, 11, -1, 4, 5, 9, -1, 0, 3, 8, -2, -1, -1, -1, -1],
                                   [11, 7, 6, -1, 1, 0, 5, 4, -2, -1, -1, -1, -1, -1, -1, -1],
                                   [11, 7, 6, -1, 8, 3, 1, 5, 4, -2, -1, -1, -1, -1, -1, -1],
                                   [11, 7, 6, -1, 4, 5, 9, -1, 1, 2, 10, -2, -1, -1, -1, -1],
                                   [11, 7, 6, -1, 4, 5, 9, -1, 1, 2, 10, -1, 0, 3, 8, -2],
                                   [11, 7, 6, -1, 0, 2, 10, 5, 4, -2, -1, -1, -1, -1, -1, -1],
                                   [11, 7, 6, -1, 8, 3, 2, 10, 5, 4, -2, -1, -1, -1, -1, -1],
                                   [4, 5, 9, -1, 3, 2, 6, 7, -2, -1, -1, -1, -1, -1, -1, -1],
                                   [4, 5, 9, -1, 2, 0, 8, 7, 6, -2, -1, -1, -1, -1, -1, -1],
                                   [3, 2, 6, 7, -1, 0, 1, 5, 4, -2, -1, -1, -1, -1, -1, -1],
                                   [1, 2, 4, 5, 6, 7, 8, -2, -1, -1, -1, -1, -1, -1, -1, -1],
                                   [9, 4, 5, -1, 1, 10, 6, 7, 3, -2, -1, -1, -1, -1, -1, -1],
                                   [9, 4, 5, -1, 6, 10, 1, 0, 8, 7, -2, -1, -1, -1, -1, -1],
                                   [0, 3, 4, 5, 6, 7, 10, -2, -1, -1, -1, -1, -1, -1, -1, -1],
                                   [4, 5, 6, 7, 8, 10, -2, -1, -1, -1, -1, -1, -1, -1, -1, -1],
                                   [5, 6, 8, 9, 11, -2, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1],
                                   [0, 3, 5, 6, 9, 11, -2, -1, -1, -1, -1, -1, -1, -1, -1, -1],
                                   [0, 1, 5, 6, 8, 11, -2, -1, -1, -1, -1, -1, -1, -1, -1, -1],
                                   [1, 3, 5, 6, 11, -2, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1],
                                   [1, 2, 10, -1, 9, 5, 6, 11, 8, -2, -1, -1, -1, -1, -1, -1],
                                   [1, 2, 10, -1, 9, 0, 3, 11, 6, 5, -2, -1, -1, -1, -1, -1],
                                   [0, 2, 5, 6, 8, 10, 11, -2, -1, -1, -1, -1, -1, -1, -1, -1],
                                   [2, 3, 5, 6, 10, 11, -2, -1, -1, -1, -1, -1, -1, -1, -1, -1],
                                   [2, 3, 5, 6, 8, 9, -2, -1, -1, -1, -1, -1, -1, -1, -1, -1],
                                   [0, 2, 5, 6, 9, -2, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1],
                                   [0, 1, 2, 3, 5, 6, 8, -2, -1, -1, -1, -1, -1, -1, -1, -1],
                                   [1, 2, 5, 6, -2, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1],
                                   [1, 3, 5, 6, 8, 9, 10, -2, -1, -1, -1, -1, -1, -1, -1, -1],
                                   [0, 1, 5, 6, 9, 10, -2, -1, -1, -1, -1, -1, -1, -1, -1, -1],
                                   [0, 3, 5, 6, 8, 10, -2, -1, -1, -1, -1, -1, -1, -1, -1, -1],
                                   [5, 6, 10, -2, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1],
                                   [5, 7, 10, 11, -2, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1],
                                   [5, 7, 10, 11, -1, 0, 3, 8, -2, -1, -1, -1, -1, -1, -1, -1],
                                   [5, 7, 10, 11, -1, 0, 1, 9, -2, -1, -1, -1, -1, -1, -1, -1],
                                   [5, 7, 10, 11, -1, 3, 8, 9, 1, -2, -1, -1, -1, -1, -1, -1],
                                   [1, 2, 5, 7, 11, -2, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1],
                                   [1, 2, 5, 7, 11, -1, 0, 3, 8, -2, -1, -1, -1, -1, -1, -1],
                                   [0, 2, 5, 7, 9, 11, -2, -1, -1, -1, -1, -1, -1, -1, -1, -1],
                                   [2, 3, 5, 7, 8, 9, 11, -2, -1, -1, -1, -1, -1, -1, -1, -1],
                                   [2, 3, 5, 7, 10, -2, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1],
                                   [0, 2, 5, 7, 8, 10, -2, -1, -1, -1, -1, -1, -1, -1, -1, -1],
                                   [0, 1, 9, -1, 7, 3, 2, 10, 5, -2, -1, -1, -1, -1, -1, -1],
                                   [1, 2, 5, 7, 8, 9, 10, -2, -1, -1, -1, -1, -1, -1, -1, -1],
                                   [1, 3, 5, 7, -2, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1],
                                   [0, 1, 5, 7, 8, -2, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1],
                                   [0, 3, 5, 7, 9, -2, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1],
                                   [5, 7, 8, 9, -2, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1],
                                   [4, 5, 8, 10, 11, -2, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1],
                                   [0, 3, 4, 5, 10, 11, -2, -1, -1, -1, -1, -1, -1, -1, -1, -1],
                                   [0, 1, 9, -1, 8, 11, 10, 4, 5, -2, -1, -1, -1, -1, -1, -1],
                                   [1, 3, 4, 5, 9, 10, 11, -2, -1, -1, -1, -1, -1, -1, -1, -1],
                                   [1, 2, 4, 5, 8, 11, -2, -1, -1, -1, -1, -1, -1, -1, -1, -1],
                                   [0, 1, 2, 3, 4, 5, 11, -2, -1, -1, -1, -1, -1, -1, -1, -1],
                                   [0, 2, 4, 5, 8, 9, 11, -2, -1, -1, -1, -1, -1, -1, -1, -1],
                                   [2, 3, 4, 5, 9, 11, -2, -1, -1, -1, -1, -1, -1, -1, -1, -1],
                                   [2, 3, 4, 5, 8, 10, -2, -1, -1, -1, -1, -1, -1, -1, -1, -1],
                                   [0, 2, 4, 5, 10, -2, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1],
                                   [0, 1, 9, -1, 8, 3, 2, 10, 5, 4, -2, -1, -1, -1, -1, -1],
                                   [1, 2, 4, 5, 9, 10, -2, -1, -1, -1, -1, -1, -1, -1, -1, -1],
                                   [1, 3, 4, 5, 8, -2, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1],
                                   [0, 1, 4, 5, -2, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1],
                                   [0, 3, 4, 5, 8, 9, -2, -1, -1, -1, -1, -1, -1, -1, -1, -1],
                                   [4, 5, 9, -2, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1],
                                   [4, 7, 9, 10, 11, -2, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1],
                                   [0, 3, 8, -1, 10, 9, 4, 7, 11, -2, -1, -1, -1, -1, -1, -1],
                                   [0, 1, 4, 7, 10, 11, -2, -1, -1, -1, -1, -1, -1, -1, -1, -1],
                                   [1, 3, 4, 7, 8, 10, 11, -2, -1, -1, -1, -1, -1, -1, -1, -1],
                                   [1, 2, 4, 7, 9, 11, -2, -1, -1, -1, -1, -1, -1, -1, -1, -1],
                                   [1, 2, 4, 7, 9, 11, -1, 0, 3, 8, -2, -1, -1, -1, -1, -1],
                                   [0, 2, 4, 7, 11, -2, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1],
                                   [2, 3, 4, 7, 8, 11, -2, -1, -1, -1, -1, -1, -1, -1, -1, -1],
                                   [2, 3, 4, 7, 9, 10, -2, -1, -1, -1, -1, -1, -1, -1, -1, -1],
                                   [0, 2, 4, 7, 8, 9, 10, -2, -1, -1, -1, -1, -1, -1, -1, -1],
                                   [0, 1, 2, 3, 4, 7, 10, -2, -1, -1, -1, -1, -1, -1, -1, -1],
                                   [1, 2, 4, 7, 8, 10, -2, -1, -1, -1, -1, -1, -1, -1, -1, -1],
                                   [1, 3, 4, 7, 9, -2, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1],
                                   [0, 1, 4, 7, 8, 9, -2, -1, -1, -1, -1, -1, -1, -1, -1, -1],
                                   [0, 3, 4, 7, -2, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1],
                                   [4, 7, 8, -2, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1],
                                   [8, 9, 10, 11, -2, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1],
                                   [0, 3, 9, 10, 11, -2, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1],
                                   [0, 1, 8, 10, 11, -2, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1],
                                   [1, 3, 10, 11, -2, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1],
                                   [1, 2, 8, 9, 11, -2, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1],
                                   [0, 1, 2, 3, 9, 11, -2, -1, -1, -1, -1, -1, -1, -1, -1, -1],
                                   [0, 2, 8, 11, -2, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1],
                                   [2, 3, 11, -2, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1],
                                   [2, 3, 8, 9, 10, -2, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1],
                                   [0, 2, 9, 10, -2, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1],
                                   [0, 1, 2, 3, 8, 10, -2, -1, -1, -1, -1, -1, -1, -1, -1, -1],
                                   [1, 2, 10, -2, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1],
                                   [1, 3, 8, 9, -2, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1],
                                   [0, 1, 9, -2, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1],
                                   [0, 3, 8, -2, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1],
                                   [-2, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1]

                               ];


uint[256] vertexNumTable = [
                                   0, 1, 1, 1, 1, 2, 1, 1, 1, 1, 2, 1, 1, 1, 1, 1,
                                   1, 1, 2, 1, 2, 2, 2, 1, 2, 1, 3, 1, 2, 1, 2, 1,
                                   1, 2, 1, 1, 2, 3, 1, 1, 2, 2, 2, 1, 2, 2, 1, 1,
                                   1, 1, 1, 1, 2, 2, 1, 1, 2, 1, 2, 1, 2, 1, 1, 1,
                                   1, 2, 2, 2, 1, 2, 1, 1, 2, 2, 3, 2, 1, 1, 1, 1,
                                   2, 2, 3, 2, 2, 2, 2, 1, 3, 2, 4, 2, 2, 1, 2, 1,
                                   1, 2, 1, 1, 1, 2, 1, 1, 2, 2, 2, 1, 1, 1, 1, 1,
                                   1, 1, 1, 1, 1, 1, 1, 1, 2, 1, 2, 1, 1, 1, 1, 1,
                                   1, 2, 2, 2, 2, 3, 2, 2, 1, 1, 2, 1, 1, 1, 1, 1,
                                   1, 1, 2, 1, 2, 2, 2, 1, 1, 1, 2, 1, 1, 1, 2, 1,
                                   2, 3, 2, 2, 3, 4, 2, 2, 2, 2, 2, 1, 2, 2, 1, 1,
                                   1, 1, 1, 1, 2, 2, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1,
                                   1, 2, 2, 2, 1, 2, 1, 1, 1, 1, 2, 1, 1, 1, 1, 1,
                                   1, 1, 2, 1, 1, 1, 1, 1, 1, 1, 2, 1, 1, 1, 1, 1,
                                   1, 2, 1, 1, 1, 2, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1,
                                   1, 2, 1, 2, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 0
                               ];




Vector3!T sampleSurfaceIntersection(T,alias DenFn3)(const ref Line!(T,3) line, size_t n, ref DenFn3 f){
    auto ext = line.end - line.start;
    auto norm = ext.norm();
    auto dir = ext / norm;

    auto center = line.start + ext * 0.5F;
    auto curExt = norm * 0.25F;

    for(size_t i = 0; i < n; ++i){
        auto point1 = center - dir * curExt;
        auto point2 = center + dir * curExt;
        auto den1 = f(point1).abs();
        auto den2 = f(point2).abs();

        if(den1 <= den2){
            center = point1;
        }else{
            center = point2;
        }

        curExt *= 0.5F;
    }

    return center;

}

Vector3!T calculateNormal(T, alias DenFn3)(Vector3!T point, T eps, ref DenFn3 f){

    T d = f(Vector3!T([point.x, point.y, point.z]));

    return Vector3!T([f(Vector3!T([point.x + eps, point.y, point.z])) - d,
                          f(Vector3!T([point.x, point.y + eps, point.z])) - d,
                          f(Vector3!T([point.x, point.y, point.z + eps])) - d]).normalize();
}


bool isConstSign(float a, float b){

    bool ac = a < 0;
    bool bc = b < 0; 
    return ac == bc; //this condition must agree with config conditions
}

//outer array corresponds to each vertex to be placed inside the cell
//inner array binds edges according to the EMCT to that vertex
Array!(Array!uint) whichEdgesAreSigned(uint config){

    int[16] entry = edgeTable[config]; //TODO inefficient coping ?
    size_t numOfVertices = vertexNumTable[config];
    if(entry[0] == -2)
        return Array!(Array!uint)();

    auto result = Array!(Array!uint)();
    result.reserve(numOfVertices);
    auto curVertex = Array!uint();
    curVertex.reserve(3);

    for(size_t i = 0; i < entry.length; ++i){
        auto k = entry[i];
        if(k >= 0){
            curVertex.insertBack(k);
        }else if(k == -2){
            result.insertBack(curVertex);
            return result;
        }else{
            result.insertBack(curVertex);
            curVertex = Array!uint();
        }
    }

    return result;
}

float calculateQEF(Vector3!float point, const ref Array!(Plane!float) planes){
    float qef = 0.0F;
    foreach(ref plane; planes[]){
        auto distSigned = plane.normal.dot(point - plane.point);
        qef += distSigned * distSigned;
    }

    return qef;
}

Vector3!float sampleQEFBrute(const ref Cube!float cube, size_t n, const ref Array!(Plane!float) planes){
    auto ext = Vector3!float([cube.extent, cube.extent, cube.extent]);
    auto min = cube.center - ext;

    auto bestQef = float.max;

    auto bestPoint = min;

    for(size_t i = 0; i < n; ++i){
        for(size_t j = 0; j < n; ++j){
            for(size_t k = 0; k < n; ++k){
                auto point = min + Vector3!float([ext.x * (2 * i + 1.0) / n, ext.y * (2 * j + 1.0) / n, ext.z * (2 * k + 1.0) / n]);
                auto qef = calculateQEF(point, planes);

                if(qef < bestQef){
                    bestQef = qef;
                    bestPoint = point;
                }
            }
        }
    }

    return bestPoint;
}


Vector3!float sampleQefBrute2(const ref Array!(Plane!float) planes, Vector3!float start){

    foreach(j; 0..1000){
        auto d = zero!(float,3,1);

        foreach(ref plane; planes){
                d = d + (start - plane.point);
        }

        d = d / planes.length;

        start = start + d * 0.7F;
    }

    return start;



}

//solves QEF as written in paper: http://www.cs.wustl.edu/~taoju/research/dualContour.pdf
Vector3!float solveQEF(const ref Array!(Plane!float) planes, Vector3!float centroid){ //TODO uses GC ! ?
    auto n = planes.length;
    auto Ab = Array!float();
    Ab.reserve(n * 4);
    Ab.length = n * 4;

    import lapacke;

    for(size_t i = 0; i < n; ++i){
        Ab[4*i]   = planes[i].normal.x;
        Ab[4*i+1] = planes[i].normal.y;
        Ab[4*i+2] = planes[i].normal.z;

        Ab[4*i+3] = planes[i].normal.dot(planes[i].point - centroid);
    }


    auto original = Ab.array;

    float[4] tau;

    auto err1 = LAPACKE_sgeqrf(LAPACK_ROW_MAJOR, cast(int)n, 4, &Ab[0], 4, tau.ptr);



    auto Af = zero!(float,3,3)();
    for(size_t i = 0; i < 3; ++i){
        for(size_t j = i; j < 3; ++j){
            Af[i,j] = Ab[4*i + j];
        }
    }

    auto bf = vec3!float(Ab[3], Ab[7], Ab[11]);

    /*auto minimizer1 = zero!(float,3,1);

    solveRxb(Af, bf, minimizer1);*/





    auto U = zero!(float,3,3);
    auto VT = U;

    auto S = zero!(float,3,1);

    float[2] cache;

    auto AfCopy = Af;

    auto res = LAPACKE_sgesvd(LAPACK_ROW_MAJOR, 'A', 'A', 3, 3, Af.array.ptr, 3, S.array.ptr, U.array.ptr, 3, VT.array.ptr, 3, cache.ptr);


    /*writeln(original);
    writeln(AfCopy);
    writeln(U);
    writeln(VT.transpose());
    writeln(S);*/

    foreach(i;0..3){
        if(S[i].abs() < 0.1F){
            S[i] = 0.0F;
        }else{
            S[i] = 1.0F / S[i];
        }
    }

    auto Sm = diag3(S[0], S[1], S[2]);

    auto pinv = mult(mult(VT.transpose(), Sm), U.transpose());

    auto minimizer = mult(pinv, bf);



    return minimizer;

}


Vector3!float solveQEF2(const ref Array!(Plane!float) planes, const ref Vector3!float meanPoint){ //TODO uses GC !
    auto n = planes.length;
    auto A = Array!float();
    A.reserve(n * 3);
    A.length = n * 3;

    auto b = Array!float();
    b.reserve(n);
    b.length = n;

    import lapacke;

    for(size_t i = 0; i < n; ++i){
        A[3*i]   = planes[i].normal.x;
        A[3*i+1] = planes[i].normal.y;
        A[3*i+2] = planes[i].normal.z;

        b[i] = planes[i].normal.dot(planes[i].point - meanPoint);
    }

    writeln("A");
    writeln(A.array);
    writeln("b");
    writeln(b.array);



    auto U = new float[n*n];
    auto VT = new float[3*3];
    auto S = zero!(float,3,1);


    auto UT = new float[n*n];
    auto V = new float[3*3];

    float[2] cache;

    auto res = LAPACKE_sgesvd(LAPACK_ROW_MAJOR, 'A', 'A', n, 3, &A[0], 3, S.array.ptr, U.ptr, n, VT.ptr, 3, cache.ptr);
    writeln(res);


    writeln("U");
    writeln(U);
    writeln("VT");
    writeln(VT);

    writeln("S");
    writeln(S);

    foreach(i;0..3){
        if(S[i].abs() < 0.1F){
            S[i] = 0.0F;
        }else{
            S[i] = 1.0F / S[i];
        }
    }

    auto Sm = new float[3 * n];
    memset(Sm.ptr, 0, float.sizeof * 3 * n);
    Sm[0] = S[0];
    Sm[4] = S[1];
    Sm[8] = S[2];

    writeln("Sm");
    writeln(Sm);

    math.transpose(U.ptr, n,n, UT.ptr);
    math.transpose(VT.ptr,3,3, V.ptr);

    writeln("UT");
    writeln(UT);
    writeln("V");
    writeln(V);



    auto pinv1 = new float[3*n]; //V * S * UT
    auto pinv = new float[3*n];

    mult(V.ptr, Sm.ptr, 3, 3, n, pinv1.ptr);
    mult(pinv1.ptr, UT.ptr, 3,n,n, pinv.ptr);


    writeln("pinv");
    writeln(pinv);



    auto minimizer = zero!(float,3,1);

    mult(pinv.ptr, &b[0], 3,n,1, minimizer.array.ptr);

    writeln(minimizer);


    return minimizer;//TODO

}

//sample density function and store(in RAM) the data in uniform format
void sample(alias DenFn3)(ref DenFn3 f, Vector3!float offset, float a, size_t accuracy, ref UniformVoxelStorage!float storage){

    auto size = storage.cellCount;


    pragma(inline,true)
    size_t indexDensity(size_t x, size_t y, size_t z){
        return z * (size + 2) * (size + 2) + y * (size + 2) + x;
    }

    pragma(inline,true)
    size_t indexCell(size_t x, size_t y, size_t z){
        return z * (size+1) * (size+1) + y * (size+1) + x; //one extra cell in each axis
    }

    pragma(inline,true)
    void loadDensity(size_t x, size_t y, size_t z){
        auto p = offset + vec3!float(x * a, y * a, z * a);
        storage.grid[indexDensity(x,y,z)] = f(p);
    }

    pragma(inline,true)
    Cube!float cube(size_t x, size_t y, size_t z){//cube bounds of a cell in the grid
        return Cube!float(offset + Vector3!float([(x + 0.5F)*a, (y + 0.5F) * a, (z + 0.5F) * a]), a / 2.0F);
    }


    pragma(inline,true)
    void loadCell(size_t x, size_t y, size_t z){

        auto cellMin = offset + Vector3!float([x * a, y * a, z * a]);
        auto bounds = cube(x,y,z);

        uint config = 0;

        if(storage.grid[indexDensity(x,y,z)] < 0.0){
            config |= 1;
        }
        if(storage.grid[indexDensity(x+1,y,z)] < 0.0){
            config |= 2;
        }
        if(storage.grid[indexDensity(x+1,y,z+1)] < 0.0){
            config |= 4;
        }
        if(storage.grid[indexDensity(x,y,z+1)] < 0.0){
            config |= 8;
        }

        if(storage.grid[indexDensity(x,y+1,z)] < 0.0){
            config |= 16;
        }
        if(storage.grid[indexDensity(x+1,y+1,z)] < 0.0){
            config |= 32;
        }
        if(storage.grid[indexDensity(x+1,y+1,z+1)] < 0.0){
            config |= 64;
        }
        if(storage.grid[indexDensity(x,y+1,z+1)] < 0.0){
            config |= 128;
        }

        int* entry = &specialTable1[config][0];

        if(*entry != -2){
            int curEntry = entry[0];
            import core.stdc.stdlib : malloc;
            HermiteData!(float)* edges = cast(HermiteData!(float)*)malloc((HermiteData!float).sizeof * 3); //TODO needs to be cleared
            while(curEntry != -2){


                auto corners = edgePairs[curEntry];
                auto edge = Line!(float,3)(cellMin + cornerPoints[corners.x] * a, cellMin + cornerPoints[corners.y] * a);
                auto intersection = sampleSurfaceIntersection!(float, DenFn3)(edge, cast(uint)accuracy.log2() + 1, f);
                auto normal = calculateNormal!(float, DenFn3)(intersection, a/1024.0F, f); //TODO division by 1024 is improper for very high sizes

               

                edges[specialTable2[curEntry]] = HermiteData!float(intersection, normal);


                curEntry = *(++entry);
            }




            storage.edgeInfo[indexCell(x,y,z)] = edges;

        }


    }


    /*foreach(z; 0..size+1){
        foreach(y; 0..size+1){
            foreach(x; 0..size+1){
                loadDensity(x,y,z);
            }
        }
    }

    foreach(z; 0..size+1){
        foreach(y; 0..size+1){
            foreach(x; 0..size+1){
                loadCell(x,y,z);
            }
        }
    }*/

    StopWatch watch;

    watch.start();


    foreach(i; parallel(iota(0, (size+1) * (size+1) * (size+1) ))){ //extra one sample in each axis does not need to be taken
        auto z = i / (size+1) / (size+1);
        auto y = i / (size+1) % (size+1);
        auto x = i % (size+1);

        loadDensity(x,y,z);
    }


    watch.stop();

    size_t ms;
    watch.peek().split!"msecs"(ms);
    watch.reset();

    printf("density sampling took %d ms\n", ms);
    stdout.flush();


    watch.start();

    foreach(i; parallel(iota(0, (size+1) * (size+1) * (size+1)))){ //extra cells are needed
        auto z = i / (size+1) / (size+1);
        auto y = i / (size+1) % (size+1);
        auto x = i % (size+1);

        loadCell(x,y,z);
    }


    watch.stop();

    watch.peek().split!"msecs"(ms);
    printf("sampling of hermite data took %d ms\n", ms);
    stdout.flush();


    //TODO here storage.data can be shrinked
    //TODO if data is modified some cells can become zero references, some may gain references so storage.data can get fragmented, so defragmentation will be required
    //TODO or store each HermiteData[3] piece seprately in memory(this will drastically increase cache misses => performance loss when reading)
}

void extract(ref UniformVoxelStorage!float storage, Vector3!float offset, float a, Vector3!float delegate(Vector3!float) colorizer, RenderVertFragDef renderTriLight, RenderVertFragDef renderLines){

    
    auto size = storage.cellCount;


    auto minimizers = Array!(Vector3!(float)[12])();
    minimizers.reserve(size * size * size);
    minimizers.length = size * size * size;

    pragma(inline,true)
    size_t indexMinimizer(size_t x, size_t y, size_t z){
        return z * size * size + y * size + x;
    }

    pragma(inline,true)
    size_t indexCell(size_t x, size_t y, size_t z){
        return z * (size+1) * (size+1) + y * (size+1) + x;
    }

    pragma(inline,true)
    size_t indexDensity(size_t x, size_t y, size_t z){
        return z * (size + 2) * (size + 2) + y * (size + 2) + x;
    }


    pragma(inline,true)
    Cube!float cube(size_t x, size_t y, size_t z){//cube bounds of a cell in the grid
        return Cube!float(offset + Vector3!float([(x + 0.5F)*a, (y + 0.5F) * a, (z + 0.5F) * a]), a / 2.0F);
    }


    //this function will find the hermite data for the edge given coordinates of the cell in which the edge is located and local index of the edge in that cell
    pragma(inline,true)
    HermiteData!(float)* indexEdge(size_t x, size_t y, size_t z, size_t index){
        auto offset = specialTable3[index];

        size_t mappedIndex = cast(size_t) specialTable2[index]; //mapped index is in integer range [0,2]
        

        // if(cast(ulong) storage.edgeInfo[indexCell(x + offset.x,y + offset.y,z + offset.z)] + mappedIndex < 100)printf("id=%d, ind=%d, ptr=%u\n, x=%u, y=%u, z=%u, j=%u", index, mappedIndex, cast(ulong) (storage.edgeInfo[indexCell(x + offset.x,y + offset.y,z + offset.z)] + mappedIndex), x,y,z, indexCell(x + offset.x,y + offset.y,z + offset.z));
        // stdout.flush();

        return storage.edgeInfo[indexCell(x + offset.x,y + offset.y,z + offset.z)] + mappedIndex;
    }




    pragma(inline,true)
    void loadCell(size_t x, size_t y, size_t z){
        //auto cellMin = offset + Vector3!float([x * a, y * a, z * a]);

        uint config = 0;

        if(storage.grid[indexDensity(x,y,z)] < 0.0){
            config |= 1;
        }
        if(storage.grid[indexDensity(x+1,y,z)] < 0.0){
            config |= 2;
        }
        if(storage.grid[indexDensity(x+1,y,z+1)] < 0.0){
            config |= 4;
        }
        if(storage.grid[indexDensity(x,y,z+1)] < 0.0){
            config |= 8;
        }

        if(storage.grid[indexDensity(x,y+1,z)] < 0.0){
            config |= 16;
        }
        if(storage.grid[indexDensity(x+1,y+1,z)] < 0.0){
            config |= 32;
        }
        if(storage.grid[indexDensity(x+1,y+1,z+1)] < 0.0){
            config |= 64;
        }
        if(storage.grid[indexDensity(x,y+1,z+1)] < 0.0){
            config |= 128;
        }


        if(config != 0 && config != 255){

            auto vertices = whichEdgesAreSigned(config);
            auto bounds = cube(x,y,z);

            foreach(ref vertex; vertices){
                auto curPlanes = Array!(Plane!float)();
                auto meanPoint = zero!(float,3,1);
                curPlanes.reserve(4);

                foreach(edgeId; vertex){

                    HermiteData!float edgeData = *indexEdge(x,y,z, edgeId);

                    //writeln(edgeData);

                    // auto edgePair = edgePairs[edgeId];
                    // auto start = cornerPoints[edgePair.x];
                    // auto end = cornerPoints[edgePair.y];

                    // start = start - Vector3!float([-0.5F, -0.5F, -0.5F]); //translate to the origin
                    // end = end - Vector3!float([-0.5F, -0.5F, -0.5F]);     //
 
                    // start = start * 2 * bounds.extent;                    //scale
                    // end = end * 2 * bounds.extent;                        //

                    // start = start + bounds.center;                        //translate to the bounds
                    // end = end + bounds.center;                            //

                    // auto zeroCrossingPoint = start + (end - start) * edgeData.intersection;



                    auto plane = Plane!float(edgeData.intersection, edgeData.normal);

                    curPlanes.insertBack(plane);
                    meanPoint = meanPoint + plane.point;

                }

                meanPoint = meanPoint / curPlanes.length;

                auto minimizer = solveQEF(curPlanes, meanPoint) + meanPoint;

                // if(!checkPointInsideCube(minimizer, bounds)){ //this removes self intersecting triangles but also makes things like sharp boxes impossible
                //     writeln("outside !");
                //     minimizer = meanPoint;
                // }

                //writeln(minimizer);

                /*writeln(meanPoint);
                writeln(minimizer);
                stdout.flush();*/

                foreach(edgeId; vertex){
                    minimizers[indexMinimizer(x,y,z)][edgeId] = minimizer;
                }


            }
        }
    }

    pragma(inline,true)
    void extactSurface(size_t x, size_t y, size_t z){

        auto d2 = storage.grid[indexDensity(x+1,y,z+1)];
        auto d5 = storage.grid[indexDensity(x+1,y+1,z)];
        auto d6 = storage.grid[indexDensity(x+1,y+1,z+1)];
        auto d7 = storage.grid[indexDensity(x,y+1,z+1)];

        uint edgeId = -1;


        if(!isConstSign(d5,d6)){ //edgeId = 5
            edgeId = 5;

            auto minimizer = minimizers[indexMinimizer(x,y,z)][edgeId];
            auto normal = (*indexEdge(x,y,z,edgeId)).normal;
            auto color = colorizer(minimizer);


            auto r = minimizers[indexMinimizer(x+1,y,z)][7];
            auto ru = minimizers[indexMinimizer(x+1,y+1,z)][3];
            auto u = minimizers[indexMinimizer(x,y+1,z)][1];

            auto rc = colorizer(r);
            auto ruc = colorizer(ru);
            auto uc = colorizer(u);



            addTriangleColorNormal(renderTriLight, Triangle!(float,3)(minimizer, r, ru), Triangle!(float,3)(color, rc, ruc), normal);
            addTriangleColorNormal(renderTriLight, Triangle!(float,3)(minimizer, ru, u), Triangle!(float,3)(color, ruc, uc), normal);
        }


        if(!isConstSign(d7,d6)){ //edgeId = 6
            edgeId = 6;

            auto minimizer = minimizers[indexMinimizer(x,y,z)][edgeId];
            auto normal = (*indexEdge(x,y,z,edgeId)).normal;
            auto color = colorizer(minimizer);

            auto f = minimizers[indexMinimizer(x,y,z+1)][4];
            auto fu = minimizers[indexMinimizer(x,y+1,z+1)][0];
            auto u = minimizers[indexMinimizer(x,y+1,z)][2];

            auto fc = colorizer(f);
            auto fuc = colorizer(fu);
            auto uc = colorizer(u);


            addTriangleColorNormal(renderTriLight, Triangle!(float,3)(minimizer, f, fu), Triangle!(float,3)(color, fc, fuc), normal);
            addTriangleColorNormal(renderTriLight, Triangle!(float,3)(minimizer, fu, u), Triangle!(float,3)(color, fuc, uc), normal);
        }

        if(!isConstSign(d2,d6)){ //edgeId = 10
            edgeId = 10;

            auto minimizer = minimizers[indexMinimizer(x,y,z)][edgeId];
            auto normal = (*indexEdge(x,y,z,edgeId)).normal;
            auto color = colorizer(minimizer);

            auto r = minimizers[indexMinimizer(x+1,y,z)][11];
            auto rf = minimizers[indexMinimizer(x+1,y,z+1)][8];
            auto f = minimizers[indexMinimizer(x,y,z+1)][9];


            auto rc = colorizer(r);
            auto rfc = colorizer(rf);
            auto fc = colorizer(f);

            addTriangleColorNormal(renderTriLight, Triangle!(float,3)(minimizer, rf, r), Triangle!(float,3)(color, rfc, rc), normal);
            addTriangleColorNormal(renderTriLight, Triangle!(float,3)(minimizer, f, rf), Triangle!(float,3)(color, fc, rfc), normal);
        }
    }


    StopWatch watch;

    size_t ms;

    watch.start();



    foreach(i; parallel(iota(0, size * size * size))){
        auto z = i / size / size;
        auto y = i / size % size;
        auto x = i % size;

        loadCell(x,y,z);
    }

    watch.stop();

    watch.peek().split!"msecs"(ms);

    printf("loading of cells took %d ms\n", ms);
    stdout.flush();

    watch.reset();

    watch.start();


    foreach(z; 0..size-1){
        foreach(y; 0..size-1){
            foreach(x; 0..size-1){
                extactSurface(x,y,z);
            }
        }
    }

    watch.stop();

    watch.peek().split!"msecs"(ms);

    printf("triangle generation took %d ms\n", ms);
    stdout.flush();




}

//5623ms
//vvv
//489 + 2303 ~~ 2792ms //200% speed increase
//500 + 700 ~~ 1200ms //another 200% speed increase !

//TODO REMOVE
//Colorizer is a function (f : Pos -> Color) for now, Pos is absolute position of feature vertex in a cell
void extract(alias DenFn3)(ref DenFn3 f, Vector3!float offset, float a, size_t size, size_t accuracy, Vector3!float delegate(Vector3!float) colorizer, RenderVertFragDef renderTriLight, RenderVertFragDef renderLines){



    //float[size + 1][size + 1][size + 1] densities; //TODO port this to stack(prob too big)
    auto densities = Array!float();
    densities.reserve((size + 1)*(size + 1)*(size + 1));
    densities.length = (size + 1)*(size + 1)*(size + 1);

    alias CellData = Tuple!(Vector3!float, "minimizer", Vector3!float, "normal"); //minimizer, normal and density sampled at zero-crossing point of that edge

    auto features = Array!(CellData[12])(); //TODO does it auto initialize hashmap ? That is a lot of extra storage !
    features.reserve(size * size * size);
    features.length = size * size * size; //make sure we can access any feature //TODO convert to static array
    //TODO switch to nogc hashmap or use arrays with O(1) access but more memory use as a tradeoff
    //TODO normals are duplicated !

    /*auto edges = Array!(CellData)();
    auto edgeCount = 3*(size + 1)*(size + 1)*size;
    features.reserve(edgeCount);
    features.length = edgeCount;*/


    pragma(inline,true)
    size_t indexDensity(size_t x, size_t y, size_t z){
        return z * (size + 1) * (size + 1) + y * (size + 1) + x;
    }

    pragma(inline,true)
    size_t indexFeature(size_t x, size_t y, size_t z){
        return z * size * size + y * size + x;
    }


    /*pragma(inline, true) //3 * (n+1)^2 * n
    size_t indexEdge(size_t x, size_t y, size_t z, size_t localEdgeId){//cell coordinates and local edge id

    }*/

    pragma(inline,true)
    Cube!float cube(size_t x, size_t y, size_t z){//cube bounds of a cell in the grid
        return Cube!float(offset + Vector3!float([(x + 0.5F)*a, (y + 0.5F) * a, (z + 0.5F) * a]), a / 2.0F);
    }

    pragma(inline,true)
    void loadDensity(size_t x, size_t y, size_t z){
        auto p = offset + vec3!float(x * a, y * a, z * a);
        densities[indexDensity(x,y,z)] = f(p);

    }

    pragma(inline,true)
    void loadCell(size_t x, size_t y, size_t z){
        auto cellMin = offset + Vector3!float([x * a, y * a, z * a]);
        auto bounds = cube(x,y,z);

        uint config = 0;
        size_t num = 0; //TODO remove (not used)

        if(densities[indexDensity(x,y,z)] < 0.0){
            config |= 1;
            num += 1;
        }
        if(densities[indexDensity(x+1,y,z)] < 0.0){
            config |= 2;
            num += 1;
        }
        if(densities[indexDensity(x+1,y,z+1)] < 0.0){
            config |= 4;
            num += 1;
        }
        if(densities[indexDensity(x,y,z+1)] < 0.0){
            config |= 8;
            num += 1;
        }

        if(densities[indexDensity(x,y+1,z)] < 0.0){
            config |= 16;
            num += 1;
        }
        if(densities[indexDensity(x+1,y+1,z)] < 0.0){
            config |= 32;
            num += 1;
        }
        if(densities[indexDensity(x+1,y+1,z+1)] < 0.0){
            config |= 64;
            num += 1;
        }
        if(densities[indexDensity(x,y+1,z+1)] < 0.0){
            config |= 128;
            num += 1;
        }


        if(config != 0 && config != 255){



            auto vertices = whichEdgesAreSigned(config);

            foreach(ref vertex; vertices){
                auto curPlanes = Array!(Plane!float)();
                auto meanPoint = zero!(float,3,1);
                curPlanes.reserve(4); //TODO find the most efficient number

                foreach(edgeId; vertex){
                    auto pair = edgePairs[edgeId];
                    auto v1 = cornerPoints[pair.x];
                    auto v2 = cornerPoints[pair.y];

                    auto edge = Line!(float,3)(cellMin + v1 * a, cellMin + v2 * a);
                    auto intersection = sampleSurfaceIntersection!(float, DenFn3)(edge, cast(uint)accuracy.log2() + 1, f);//duplication here(same edge can be sampled 1 to 4 times)
                    auto normal = calculateNormal!(float, DenFn3)(intersection, a/1024.0F, f);

                    //if(x == 45 && y == 54 && z == 69)addCubeBounds(renderLines, Cube!float(intersection, a/15.0F), Vector3!float([1,0,0]));//debug intersection
                    //if(x == 45 && y == 54 && z == 69)addLine3Color(renderLines, Line!(float,3)(intersection, intersection + normal * a / 3.0F), Vector3!float([0,0,1]));

                    auto plane = Plane!float(intersection, normal);

                    curPlanes.insertBack(plane);
                    meanPoint = meanPoint + intersection;


                    CellData cellData;
                    cellData.normal = normal;
                    features[indexFeature(x,y,z)][edgeId] = cellData;
                }

                meanPoint = meanPoint / curPlanes.length;

                //auto minimizer = bounds.center;
                //auto minimizer = sampleQefBrute2(curPlanes, meanPoint);
                auto minimizer = solveQEF(curPlanes, meanPoint) + meanPoint;


                if(!checkPointInsideCube(minimizer, bounds)){
                    //addCubeBounds(renderLines, bounds, Vector3!float([1,1,1])); //debug grid
                    //addCubeBounds(renderLines, Cube!float(minimizer, a/15.0F), Vector3!float([1,1,0]));//debug minimizer
                }



                foreach(edgeId; vertex){
                    features[indexFeature(x,y,z)][edgeId].minimizer = minimizer;
                }


            }
        }
    }

    pragma(inline,true)
    void extactSurface(size_t x, size_t y, size_t z){
        auto cell = features[indexFeature(x,y,z)]; //no need for reference store here as assoc array is a class


        auto d2 = densities[indexDensity(x+1,y,z+1)];
        auto d5 = densities[indexDensity(x+1,y+1,z)];
        auto d6 = densities[indexDensity(x+1,y+1,z+1)];
        auto d7 = densities[indexDensity(x,y+1,z+1)];

        uint edgeId = -1;


        //TODO investigate: exist cells that are not initialized but isConstSign returns false
        //it turns out that parallel exucution of loadDensities yields NaN values, why ?
        if(!isConstSign(d5,d6)){ //edgeId = 5
            edgeId = 5;

            auto data = cell[edgeId];
            auto normal = data.normal;
            auto color = colorizer(data.minimizer);


            auto r = features[indexFeature(x+1,y,z)][7];
            auto ru = features[indexFeature(x+1,y+1,z)][3];
            auto u = features[indexFeature(x,y+1,z)][1];



            addTriangleColorNormal(renderTriLight, Triangle!(float,3)(data.minimizer, r.minimizer, ru.minimizer), color, normal);
            addTriangleColorNormal(renderTriLight, Triangle!(float,3)(data.minimizer, ru.minimizer, u.minimizer), color, normal);
        }


        if(!isConstSign(d7,d6)){ //edgeId = 6
            edgeId = 6;

            auto data = cell[edgeId];
            auto normal = data.normal;
            auto color = colorizer(data.minimizer);
            if(isNaN(data.minimizer.x)){ //debug
                writeln(d7);
                writeln(d6);
            }

            auto f = features[indexFeature(x,y,z+1)][4];
            auto fu = features[indexFeature(x,y+1,z+1)][0];
            auto u = features[indexFeature(x,y+1,z)][2];


            addTriangleColorNormal(renderTriLight, Triangle!(float,3)(data.minimizer, f.minimizer, fu.minimizer), color, normal);
            addTriangleColorNormal(renderTriLight, Triangle!(float,3)(data.minimizer, fu.minimizer, u.minimizer), color, normal);
        }

        if(!isConstSign(d2,d6)){ //edgeId = 10
            edgeId = 10;

            auto data = cell[edgeId];
            auto normal = data.normal;
            auto color = colorizer(data.minimizer);

            auto r = features[indexFeature(x+1,y,z)][11];
            auto rf = features[indexFeature(x+1,y,z+1)][8];
            auto f = features[indexFeature(x,y,z+1)][9];

            addTriangleColorNormal(renderTriLight, Triangle!(float,3)(data.minimizer, rf.minimizer, r.minimizer), color, normal);
            addTriangleColorNormal(renderTriLight, Triangle!(float,3)(data.minimizer, f.minimizer, rf.minimizer), color, normal);
        }

        //another variant used with assoc array
        /*foreach(ref edgeIdAndMinimizer; cell.byKeyValue){
            auto edgeId = edgeIdAndMinimizer.key;
            auto data = edgeIdAndMinimizer.value;

            auto normal = data.normal;

            if(edgeId == 5){
                auto r = features[indexFeature(x+1,y,z)][7];
                auto ru = features[indexFeature(x+1,y+1,z)][3];
                auto u = features[indexFeature(x,y+1,z)][1];


                addTriangleColorNormal(renderTriLight, Triangle!(float,3)(data.minimizer, r.minimizer, ru.minimizer), color, normal);
                addTriangleColorNormal(renderTriLight, Triangle!(float,3)(data.minimizer, ru.minimizer, u.minimizer), color, normal);
            }else if(edgeId == 6){
                auto f = features[indexFeature(x,y,z+1)][4];
                auto fu = features[indexFeature(x,y+1,z+1)][0];
                auto u = features[indexFeature(x,y+1,z)][2];

                addTriangleColorNormal(renderTriLight, Triangle!(float,3)(data.minimizer, f.minimizer, fu.minimizer), color, normal);
                addTriangleColorNormal(renderTriLight, Triangle!(float,3)(data.minimizer, fu.minimizer, u.minimizer), color, normal);
            }else if(edgeId == 10){
                auto r = features[indexFeature(x+1,y,z)][11];
                auto rf = features[indexFeature(x+1,y,z+1)][8];
                auto f = features[indexFeature(x,y,z+1)][9];

                addTriangleColorNormal(renderTriLight, Triangle!(float,3)(data.minimizer, rf.minimizer, r.minimizer), color, normal);
                addTriangleColorNormal(renderTriLight, Triangle!(float,3)(data.minimizer, f.minimizer, rf.minimizer), color, normal);

            }
        }*/
    }

    StopWatch watch;


    watch.start();


    /*foreach(z; 0..size+1){
        foreach(y; 0..size+1){
            foreach(x; 0..size+1){
                loadDensity(x,y,z);
            }
        }
    }*/

    foreach(i; parallel(iota(0, (size+1) * (size+1) * (size+1) ))){
        auto z = i / (size+1) / (size+1);
        auto y = i / (size+1) % (size+1);
        auto x = i % (size+1);

        loadDensity(x,y,z);
    }

    watch.stop();

    ulong ms;
    watch.peek().split!"msecs"(ms);

    writeln("loading of densities took " ~ to!string(ms) ~ " ms");
    stdout.flush();

    watch.reset();
    watch.start();

    /*foreach(z; 0..size){
        foreach(y; 0..size){
            foreach(x; 0..size){
                loadCell(x,y,z);
            }
        }
    }*/

    foreach(i; parallel(iota(0, size * size * size))){
        auto z = i / size / size;
        auto y = i / size % size;
        auto x = i % size;

        loadCell(x,y,z);
    }

    watch.stop();

    watch.peek().split!"msecs"(ms);

    writeln("loading of cells took " ~ to!string(ms) ~ " ms");
    stdout.flush();

    watch.reset();
    watch.start();

    foreach(z; 0..size-1){
        foreach(y; 0..size-1){
            foreach(x; 0..size-1){
                extactSurface(x,y,z);
            }
        }
    }

   /* foreach(i; parallel(iota(0, (size-1) * (size-1) * (size-1)))){
        auto z = i / (size-1) / (size-1);
        auto y = (i / (size-1)) % (size-1);
        auto x = i % (size-1);

        extactSurface(x,y,z);
    }*/

    watch.stop();


    watch.peek().split!"msecs"(ms);
    writeln("isosurface extraction took " ~ to!string(ms) ~ " ms");
    stdout.flush();

}