module Main

import IO;
import lang::java::m3::Core;
import lang::java::m3::AST;
import util::Math;
import Set;



int main(int testArgument=0) {
    println("Main running..");
    loc projectLocation = |cwd:///testProject0/|;
    //println(getASTs(projectLocation));
    println(getLOC(getASTs(projectLocation)));
    return testArgument;
}


list[Declaration] getASTs(loc projectLocation) {
    M3 model = createM3FromMavenProject(projectLocation);
    list[Declaration] asts = [createAstFromFile(f, true)
    | f <- files(model.containment), isCompilationUnit(f)];
    return asts;
}

int getNumberOfInterfaces(list[Declaration] asts){
    int interfaces = 0;
    visit(asts){
    case \interface(_, _, _, _): interfaces += 1;
    }
    return interfaces;
}

set[int] get_unique_lines{Declaration x} {
    set[int] unique_lines = {};
    // if (x.src != |unknown:///|) {
    //     println(x.src.begin.line);
    //     unique_lines += x.src.begin.line;
    //     unique_lines += x.src.begin.line;
    // }
    return unique_lines;
}

int getLOC(list[Declaration] asts) {
    set[int] unique_lines = {};
    visit(asts) {
        case Declaration x: {
            println(x.src);
            if (x.src != |unknown:///|) {
                println(x.src.begin.line);
                unique_lines += x.src.begin.line;
                unique_lines += x.src.begin.line;
            }
        }
    }
    return size(unique_lines);
}

//unique_lines += x.src.begin.line;

// int getLOC(list[Declaration] asts) {
//     set[int] unique_lines = {};
//     for(/node n <- asts) {
//             println(n.src);
//             if (n.src != |unknown:///|) {
//                 println(n.src.begin.line);
//                 unique_lines += n.src.begin.line;
//                 unique_lines += n.src.end.line;
//             }
//     }
//     return size(unique_lines);