#include "mex.h"
#include <iostream>
#include <fstream>
#include "RMarkers.h"

using namespace std;
using namespace render::util;
#define MAXRENDER 5

typedef struct
{
	RMarker start;
	RMarker end;
	RMarker render[MAXRENDER];
	int nrender;
	RMarker blocked;
	RMarker unblocked;
	RMarkerTS ts;
} RMarkerHolder;


void getMS(RMarkerHolder& holder, RMarkerTS& rate, double& s, double& e, double r[], double& b1, double& b2);
void getMSE(RMarkerHolder& holder, RMarkerTS& rate, double& s, double& e);
int parsefile(char *filename);


//===============


void mexFunction( int nlhs, mxArray *plhs[],
                  int nrhs, const mxArray *prhs[] )
{
	char *filename;

    /* check input arg */
    if(nrhs!=1)
    {
    	mexErrMsgTxt("One input required.");
    }
    else if ( mxIsChar(prhs[0]) != 1)
    {
        mexErrMsgTxt("Input must be a string.");
    }
    else if (mxGetM(prhs[0]) != 1)
    {
    	mexErrMsgTxt("Input string must be a row vector.");
    }

    filename = mxArrayToString(prhs[0]);
    if (!filename)
    {
    	mexErrMsgTxt("Cannot convert input filename to a string!");
    }

    parsefile(filename);
    mxFree(filename);

}

//===============






void getMS(RMarkerHolder& holder, RMarkerTS& rate, double& s, double& e, double r[], double& b1, double& b2)
{
	int i;
	s = ((double)(holder.start.ts - holder.ts))/(double)rate*1000.0;
	e = ((double)(holder.end.ts - holder.ts))/(double)rate*1000.0;
	for (i=0; i<holder.nrender; i++)
	{
		r[i] = ((double)(holder.render[i].ts - holder.ts))/(double)rate*1000.0;
	}
	b1 = ((double)(holder.blocked.ts - holder.ts))/(double)rate*1000.0;
	b2 = ((double)(holder.unblocked.ts - holder.ts))/(double)rate*1000.0;
}

void getMSE(RMarkerHolder& holder, RMarkerTS& rate, double& s, double& e)
{
	s = ((double)(holder.start.ts - holder.ts))/(double)rate*1000.0;
	e = ((double)(holder.end.ts - holder.ts))/(double)rate*1000.0;
}

int parsefile(char *filename)
{
	RMarker marker;
	RMarkerTS rate;
	RMarkerTS current = 0;

	// for new type add RMarkerHolder(s) adn bool below.
	RMarkerHolder holderFrame, holderInput, holderExe, holderWindow, holderTest;
	bool bFrame=false;
	bool bInput=false;
	bool bExe=false;
	bool bWindow=false;
	bool bTest=false;
	double stime, etime, rtime[MAXRENDER], b1time, b2time;
	int i;

	ifstream in(filename, ios::in | ios::binary);
	if (!in.is_open())
	{
		mexErrMsgTxt("Cannot open input file");	// exits here
	}
	marker.ts = 0;
	marker.type = 0;
	marker.val = 0;
	holderFrame.nrender = 0;
	while (in >> marker)
	{
		switch (marker.type)
		{
			case mtMarker:
				current = marker.ts;
				cout << "Marker " << marker << "(" << marker.val << ") " << endl;
				break;	// no handling for these
			case mtRate:
				rate = marker.ts;
				cout << "Rate " << marker << endl;
				break;
			case mtFrameStart:
				if (bFrame)
				{
					cout << "ERROR: Unfinished frame!" << endl;
				}
				holderFrame.start = marker;
				holderFrame.ts = current;
				bFrame = true;
				break;
			case mtFrameEnd:
				if (!bFrame)
				{
					cout << "ERROR: FrameEnd without FrameStart!" << endl;
				}
				else
				{
					holderFrame.end = marker;
//					cout << "Frame " << holderFrame.start << " - " << holderFrame.end << endl;
//					cout << "Frame " << holderFrame.start.ts - holderFrame.ts << " - " << holderFrame.end.ts - holderFrame.ts << endl;
					getMS(holderFrame, rate, stime, etime, rtime, b1time, b2time);
					cout << "Frame " << "(" << holderFrame.start.val << ") "  << stime << " - [";
					for (i=0; i<holderFrame.nrender; i++)
							cout << rtime[i] << " ";
					holderFrame.nrender = 0;
					cout << "] - " << b1time << " - " << b2time << " - " << etime << endl;
				}
				bFrame = false;
				break;
			case mtFrameRender:
				if (!bFrame)
				{
					cout << "ERROR: FrameRender without FrameStart!" << endl;
				}
				holderFrame.render[holderFrame.nrender++] = marker;
				break;
			case mtFrameBlocked:
				if (!bFrame)
				{
					cout << "ERROR: FrameBlocked without FrameStart!" << endl;
				}
				holderFrame.blocked = marker;
				break;
			case mtFrameUnblocked:
				if (!bFrame)
				{
					cout << "ERROR: FrameUnblocked without FrameStart!" << endl;
				}
				holderFrame.unblocked = marker;
				break;
			case mtInputStart:
				if (bInput)
				{
					cout << "ERROR: Unfinished input!" << endl;
				}
				holderInput.start = marker;
				holderInput.ts = current;
				bInput = true;
				break;
			case mtInputEnd:
				if (!bInput)
				{
					cout << "ERROR: InputEnd without InputStart!" << endl;
				}
				else
				{
					holderInput.end = marker;
//					cout << "Input " << holderInput.start.ts - holderInput.ts << " - " << holderInput.end.ts - holderInput.ts << endl;
					getMSE(holderInput, rate, stime, etime);
					cout << "Input " << "(" << holderInput.start.val << ") "  << stime << " - " << etime << endl;
				}
				bInput = false;
				break;
			case mtExeStart:
				if (bExe)
				{
					cout << "ERROR: Unfinished exe!" << endl;
				}
				holderExe.start = marker;
				holderExe.ts = current;
				bExe = true;
				break;
			case mtExeEnd:
				if (!bExe)
				{
					cout << "ERROR: ExeEnd without ExeStart!" << endl;
				}
				else
				{
					holderExe.end = marker;
//					cout << "Exe " << holderExe.start.ts - holderExe.ts << " - " << holderExe.end.ts - holderExe.ts << endl;
					getMSE(holderExe, rate, stime, etime);
					cout << "Exe " << "(" << holderExe.start.val << ") "  << stime << " - " << etime << endl;
				}
				bExe = false;
				break;
			case mtWindowStart:
				if (bWindow)
				{
					cout << "ERROR: Unfinished window!" << endl;
				}
				holderWindow.start = marker;
				holderWindow.ts = current;
				bWindow = true;
				break;
			case mtWindowEnd:
				if (!bWindow)
				{
					cout << "ERROR: WindowEnd without WindowStart!" << endl;
				}
				else
				{
					holderWindow.end = marker;
//					cout << "Window " << holderWindow.start.ts - holderWindow.ts << " - " << holderWindow.end.ts - holderWindow.ts << endl;
					getMSE(holderWindow, rate, stime, etime);
					cout << "Window " << "(" << holderWindow.start.val << ") "  << stime << " - " << etime << endl;
				}
				bWindow = false;
				break;
			case mtTestBegin:
				if (bTest)
				{
					cout << "ERROR: Unfinished test!" << endl;
				}
				holderTest.start = marker;
				holderTest.ts = current;
				bTest = true;
				break;
			case mtTestEnd:
				if (!bTest)
				{
					cout << "ERROR: TestEnd without TestBegin!" << endl;
				}
				else
				{
					holderTest.end = marker;
//					cout << "Exe " << holderExe.start.ts - holderExe.ts << " - " << holderExe.end.ts - holderExe.ts << endl;
					getMSE(holderTest, rate, stime, etime);
					cout << "Test " << "(" << holderTest.start.val << ") "  << stime << " - " << etime << endl;
				}
				bTest = false;
				break;
		}

	}
	in.close();
	return 0;
}
