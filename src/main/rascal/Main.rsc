module Main

import IO;
import lang::java::m3::Core;
import lang::java::m3::AST;
import util::Math;
import Map;



int main(int testArgument=0) {
    println("argument: <testArgument>");
    loc projectLocation = |cwd:///testProject0/|;
    //println(getASTs(projectLocation));
    getLOC(getASTs(projectLocation));
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

void getLOC(list[Declaration] asts) {
    set[int] unique_lines = {};
    visit(asts) {
        case Declaration x: {
            loc location = x.src;
            unique_lines += location.begin.line;
            println(location.begin.line);
        }
    }
    println("hi");
    println(unique_lines);
    return; //size(lines);
}

//unique_lines += x.src.begin.line;