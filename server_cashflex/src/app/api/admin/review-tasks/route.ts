import { NextRequest, NextResponse } from 'next/server';
import { db } from '@/lib/firebase-admin';
import { verifyAdminAuth } from '@/lib/middleware/admin-auth';

// GET - Retrieve all review tasks
export async function GET(request: NextRequest) {
  try {
    const adminContext = await verifyAdminAuth(request);
    if (!adminContext) {
      return NextResponse.json({ error: 'Unauthorized' }, { status: 401 });
    }

    const reviewTasksSnapshot = await db.collection('reviewTask').get();
    const reviewTasks = reviewTasksSnapshot.docs.map(doc => ({
      id: doc.id,
      ...doc.data(),
    }));

    return NextResponse.json(reviewTasks);
  } catch (error) {
    console.error('Error fetching review tasks:', error);
    return NextResponse.json(
      { error: 'Internal server error' },
      { status: 500 }
    );
  }
}

// POST - Create a new review task
export async function POST(request: NextRequest) {
  try {
    const adminContext = await verifyAdminAuth(request);
    if (!adminContext) {
      return NextResponse.json({ error: 'Unauthorized' }, { status: 401 });
    }

    const body = await request.json();
    
    // Validate required fields
    if (!body.link || !body.img) {
      return NextResponse.json(
        { error: 'Link and image URL are required' },
        { status: 400 }
      );
    }

    // Prepare review task data
    const reviewTaskData = {
      clipboardEnabled: body.clipboardEnabled ?? false,
      description: body.description || '',
      enabled: body.enabled ?? false,
      coins: Number.isFinite(Number(body.coins)) ? Number(body.coins) : 150,
      minBackgroundTime: Number.isFinite(Number(body.minBackgroundTime))
        ? Number(body.minBackgroundTime)
        : 60,
      img: body.img,
      link: body.link,
    };

    const docRef = await db.collection('reviewTask').add(reviewTaskData);

    return NextResponse.json({ 
      success: true, 
      id: docRef.id,
      message: 'Review task created successfully' 
    });
  } catch (error) {
    console.error('Error creating review task:', error);
    return NextResponse.json(
      { error: 'Internal server error' },
      { status: 500 }
    );
  }
}

// PUT - Update a review task
export async function PUT(request: NextRequest) {
  try {
    const adminContext = await verifyAdminAuth(request);
    if (!adminContext) {
      return NextResponse.json({ error: 'Unauthorized' }, { status: 401 });
    }

    const body = await request.json();
    
    if (!body.id) {
      return NextResponse.json(
        { error: 'Task ID is required' },
        { status: 400 }
      );
    }

    // Prepare update data
    const updateData: any = {};
    if (body.clipboardEnabled !== undefined) updateData.clipboardEnabled = body.clipboardEnabled;
    if (body.description !== undefined) updateData.description = body.description;
    if (body.enabled !== undefined) updateData.enabled = body.enabled;
    if (body.img !== undefined) updateData.img = body.img;
    if (body.link !== undefined) updateData.link = body.link;
    if (body.coins !== undefined) {
      const coins = Number(body.coins);
      if (!Number.isFinite(coins) || coins < 0) {
        return NextResponse.json({ error: 'coins must be a non-negative number' }, { status: 400 });
      }
      updateData.coins = coins;
    }
    if (body.minBackgroundTime !== undefined) {
      const t = Number(body.minBackgroundTime);
      if (!Number.isFinite(t) || t < 0) {
        return NextResponse.json({ error: 'minBackgroundTime must be a non-negative number' }, { status: 400 });
      }
      updateData.minBackgroundTime = t;
    }

    await db.collection('reviewTask').doc(body.id).update(updateData);

    return NextResponse.json({ 
      success: true, 
      message: 'Review task updated successfully' 
    });
  } catch (error) {
    console.error('Error updating review task:', error);
    return NextResponse.json(
      { error: 'Internal server error' },
      { status: 500 }
    );
  }
}

// DELETE - Delete a review task
export async function DELETE(request: NextRequest) {
  try {
    const adminContext = await verifyAdminAuth(request);
    if (!adminContext) {
      return NextResponse.json({ error: 'Unauthorized' }, { status: 401 });
    }

    const { searchParams } = new URL(request.url);
    const id = searchParams.get('id');

    if (!id) {
      return NextResponse.json(
        { error: 'Task ID is required' },
        { status: 400 }
      );
    }

    await db.collection('reviewTask').doc(id).delete();

    return NextResponse.json({ 
      success: true, 
      message: 'Review task deleted successfully' 
    });
  } catch (error) {
    console.error('Error deleting review task:', error);
    return NextResponse.json(
      { error: 'Internal server error' },
      { status: 500 }
    );
  }
}

