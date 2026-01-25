import { NextRequest, NextResponse } from "next/server"
import { db } from "@/lib/firebase-admin"
import { verifyAdminAuth } from "@/lib/middleware/admin-auth"

interface WalletCatalogItem {
  id?: string
  country?: string[]
  curFactor?: number
  enabled?: boolean
  ex_country?: string[]
  imageUrl?: string
  instructions?: string
  symbol?: string
  title?: string
  denominations?: Denomination[]
}

interface Denomination {
  id?: string
  amount?: number
  coins?: number
  enabled?: boolean
  imageUrl?: string
}

// GET - fetch all wallet catalog items
export async function GET(request: NextRequest) {
  try {
    const adminContext = await verifyAdminAuth(request)
    if (!adminContext) {
      return NextResponse.json({ error: "Unauthorized" }, { status: 401 })
    }

    const walletCatalogSnapshot = await db.collection("walletCatalog").get()
    const items: WalletCatalogItem[] = []

    for (const doc of walletCatalogSnapshot.docs) {
      const data = doc.data()
      const denominationsSnapshot = await doc.ref.collection("denominations").get()
      const denominations: Denomination[] = denominationsSnapshot.docs.map((denomDoc) => ({
        id: denomDoc.id,
        ...denomDoc.data(),
      }))

      items.push({
        id: doc.id,
        ...data,
        denominations,
      })
    }

    return NextResponse.json({ items })
  } catch (error) {
    console.error("Error fetching wallet catalog:", error)
    return NextResponse.json({ error: "Internal server error" }, { status: 500 })
  }
}

// POST - create a new wallet catalog item
export async function POST(request: NextRequest) {
  try {
    const adminContext = await verifyAdminAuth(request)
    if (!adminContext) {
      return NextResponse.json({ error: "Unauthorized" }, { status: 401 })
    }

    const body = (await request.json()) as WalletCatalogItem & { denominations?: Denomination[] }

    if (!body.id || !body.title) {
      return NextResponse.json(
        { error: "id and title are required" },
        { status: 400 }
      )
    }

    const { id, denominations, ...walletData } = body

    // Create the wallet catalog item
    await db.collection("walletCatalog").doc(id).set({
      country: walletData.country || [],
      curFactor: walletData.curFactor || 100,
      enabled: walletData.enabled ?? true,
      ex_country: walletData.ex_country || [],
      imageUrl: walletData.imageUrl || "",
      instructions: walletData.instructions || "",
      symbol: walletData.symbol || "",
      title: walletData.title,
    })

    // Add denominations if provided
    if (denominations && denominations.length > 0) {
      const batch = db.batch()
      for (const denom of denominations) {
        if (denom.id) {
          const denomRef = db
            .collection("walletCatalog")
            .doc(id)
            .collection("denominations")
            .doc(denom.id)
          batch.set(denomRef, {
            amount: denom.amount || 0,
            coins: denom.coins || 0,
            enabled: denom.enabled ?? true,
            imageUrl: denom.imageUrl || "",
          })
        }
      }
      await batch.commit()
    }

    return NextResponse.json({
      success: true,
      message: `Wallet catalog item ${id} created successfully`,
    })
  } catch (error) {
    console.error("Error creating wallet catalog item:", error)
    return NextResponse.json({ error: "Internal server error" }, { status: 500 })
  }
}

// PUT - update a wallet catalog item
export async function PUT(request: NextRequest) {
  try {
    const adminContext = await verifyAdminAuth(request)
    if (!adminContext) {
      return NextResponse.json({ error: "Unauthorized" }, { status: 401 })
    }

    const body = (await request.json()) as WalletCatalogItem & { denominations?: Denomination[] }

    if (!body.id) {
      return NextResponse.json({ error: "id is required" }, { status: 400 })
    }

    const { id, denominations, ...walletData } = body

    // Update the wallet catalog item
    const updateData: any = {}
    if (walletData.country !== undefined) updateData.country = walletData.country
    if (walletData.curFactor !== undefined) updateData.curFactor = walletData.curFactor
    if (walletData.enabled !== undefined) updateData.enabled = walletData.enabled
    if (walletData.ex_country !== undefined) updateData.ex_country = walletData.ex_country
    if (walletData.instructions !== undefined) updateData.instructions = walletData.instructions
    if (walletData.imageUrl !== undefined) updateData.imageUrl = walletData.imageUrl
    if (walletData.symbol !== undefined) updateData.symbol = walletData.symbol
    if (walletData.title !== undefined) updateData.title = walletData.title

    await db.collection("walletCatalog").doc(id).update(updateData)

    // Update denominations if provided
    if (denominations) {
      const batch = db.batch()
      const existingDenomsSnapshot = await db
        .collection("walletCatalog")
        .doc(id)
        .collection("denominations")
        .get()

      // Delete existing denominations not in the new list
      const newDenomIds = denominations.filter((d) => d.id).map((d) => d.id!)
      for (const existingDenom of existingDenomsSnapshot.docs) {
        if (!newDenomIds.includes(existingDenom.id)) {
          batch.delete(existingDenom.ref)
        }
      }

      // Add or update denominations
      for (const denom of denominations) {
        if (denom.id) {
          const denomRef = db
            .collection("walletCatalog")
            .doc(id)
            .collection("denominations")
            .doc(denom.id)
          batch.set(denomRef, {
            amount: denom.amount || 0,
            coins: denom.coins || 0,
            enabled: denom.enabled ?? true,
            imageUrl: denom.imageUrl || "",
          })
        }
      }
      await batch.commit()
    }

    return NextResponse.json({
      success: true,
      message: `Wallet catalog item ${id} updated successfully`,
    })
  } catch (error) {
    console.error("Error updating wallet catalog item:", error)
    return NextResponse.json({ error: "Internal server error" }, { status: 500 })
  }
}

// DELETE - delete a wallet catalog item
export async function DELETE(request: NextRequest) {
  try {
    const adminContext = await verifyAdminAuth(request)
    if (!adminContext) {
      return NextResponse.json({ error: "Unauthorized" }, { status: 401 })
    }

    const { searchParams } = new URL(request.url)
    const id = searchParams.get("id")

    if (!id) {
      return NextResponse.json({ error: "id is required" }, { status: 400 })
    }

    // Delete all denominations first
    const denominationsSnapshot = await db
      .collection("walletCatalog")
      .doc(id)
      .collection("denominations")
      .get()

    const batch = db.batch()
    for (const denom of denominationsSnapshot.docs) {
      batch.delete(denom.ref)
    }
    await batch.commit()

    // Delete the wallet catalog item
    await db.collection("walletCatalog").doc(id).delete()

    return NextResponse.json({
      success: true,
      message: `Wallet catalog item ${id} deleted successfully`,
    })
  } catch (error) {
    console.error("Error deleting wallet catalog item:", error)
    return NextResponse.json({ error: "Internal server error" }, { status: 500 })
  }
}

