import { NextRequest, NextResponse } from 'next/server';

export async function GET(request: NextRequest) {
  try {
    const time = Date.now();
    const current = new Date(time - 45000000);
    const convert = new Date(
      `${current.getMonth() + 1} ${current.getDate()}, ${current.getFullYear()} 23:59:59:30`,
    );
    const leadTime: number = convert.getTime() - current.getTime();

    return NextResponse.json({
      status: 'success',
      serverTime: time,
      leaderboardTimeLeft: leadTime,
    });
  } catch (error) {
    console.error(error);

    return NextResponse.json(
      {
        status: 'failure',
        reason: error,
      },
      { status: 500 },
    );
  }
}

